require "csv"

class WordsController < ApplicationController
  include DateParsing

  before_action :secure_behind_subscription
  before_action :set_word, only: [:show, :edit, :update, :destroy, :toggle_card_created]

  ORDERED_CSV_FIELDS = [
    :english,
    :japanese,
    :source_name,
    :source_reference,
    :cards_created,
    :cards_created_on,
    :added_to_list_on,
    :note
  ]
  WORDS_PER_PAGE = 10
  MAX_SEARCH_LENGTH = 30
  WORD_BATCH_SIZE = 1000

  def index
    @page = filter_params[:page] ? filter_params[:page].to_i : 1 # force pagination to conserve memory
    @offset = (@page - 1) * WORDS_PER_PAGE
    @order = filter_params[:order] == "oldest_first" ? :asc : :desc

    @words = @current_user.words.order(added_to_list_at: @order).order(created_at: @order)
    if filter_params[:search]
      @words = @words.where("english ILIKE :search OR japanese ILIKE :search", search: "%#{filter_params[:search][0..MAX_SEARCH_LENGTH - 1]}%")
    end
    @words = @words.cards_not_created if filter_params[:filter] == "cards_not_created"

    @words = @words.offset(@offset).limit(WORDS_PER_PAGE)
    @next_page = @page + 1 if @words.size == WORDS_PER_PAGE
  end

  def search
  end

  def show
  end

  def new
    @word = Word.new
  end

  def edit
  end

  def create
    @word = Word.new(word_params.merge({ user: @current_user, added_to_list_at: Time.now.utc }))

    if @word.save
      respond_to do |format|
        format.turbo_stream { flash.now[:success] = "'#{@word.japanese}' was successfully created." }
        format.html { redirect_to words_url, success: "'#{@word.japanese}' was successfully created." }
      end
    else
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "Unable to create word: #{@word.errors.full_messages.join(", ")}" }
        format.html { redirect_to new_word_path, notice: "Unable to create word: #{@word.errors.full_messages.join(", ")}" }
      end
    end
  end

  def update
    if @word.update(word_params)
      respond_to do |format|
        format.turbo_stream { flash.now[:success] = "'#{@word.japanese}' was successfully updated." }
        format.html { redirect_to @word, success: "'#{@word.japanese}' was successfully updated." }
      end
    else
      flash[:notice] = "Unable to update word: #{@word.errors.full_messages.map(&:downcase).join(", ")}"
      redirect_to edit_word_path(@word)
    end
  end

  def destroy
    @word.destroy
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = "'#{@word.japanese}' was successfully deleted." }
      format.html { redirect_to words_path, notice: "'#{@word.japanese}' was successfully deleted." }
    end
  end

  def destroy_all
    destroyed_words_count = @current_user.words.destroy_all.size
    redirect_to in_out_user_path(@current_user), success: "#{destroyed_words_count} #{"word".pluralize(destroyed_words_count)} deleted."
  end

  def toggle_card_created
    if @word.cards_created?
      @word.update!(cards_created: false, cards_created_at: nil)
    else
      @word.update!(cards_created: true, cards_created_at: Time.now.utc)
    end
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @word }
    end
  end

  def import
  end

  def export
  end

  def upload
    unless params[:csv_file]&.content_type == "text/csv"
      return redirect_to import_words_path, alert: "Missing CSV file or unsupported file format"
    end

    words_added = 0
    words_updated = 0
    words_already_exist = 0
    CSV.read(params[:csv_file].path).each_with_index do |row, index|
      if index.zero?
        return redirect_to import_words_path, alert: "Incorrectly formatted CSV" if row.size != ORDERED_CSV_FIELDS.size
        next if params[:csv_includes_headers]
      end

      english = row[0]
      japanese = row[1]
      source_name = row[2].presence
      source_reference = row[3].presence
      cards_created = ["true", "t", "x", "yes", "y"].include?(row[4].downcase)
      cards_created_at = row[5].presence && date_or_time_from(row[5])
      added_to_list_at = row[6].presence && date_or_time_from(row[6])
      note = row[7].presence

      if (word = Word.find_by(english: english, japanese: japanese, user: @current_user))
        if params[:overwrite_matching_words]
          words_updated += 1 if word.update(
            source_name: source_name,
            source_reference: source_reference,
            cards_created: cards_created,
            cards_created_at: cards_created_at,
            added_to_list_at: added_to_list_at,
            note: note
          )
        end

        next words_already_exist += 1
      end

      words_added += 1 if Word.create(
        english: english,
        japanese: japanese,
        source_name: source_name,
        source_reference: source_reference,
        cards_created: cards_created,
        cards_created_at: cards_created_at,
        added_to_list_at: added_to_list_at,
        note: note,
        user: @current_user
      )
    end

    if @current_user.has_reached_word_limit?
      flash[:alert] = "You have reached your #{view_context.link_to("word limit", content_limits_path)}. Some new words may not have been added."
    end

    flash[:success] =
      if params[:overwrite_matching_words]
        "#{words_updated} existing #{"word".pluralize(words_updated)} updated, #{words_added} new #{"word".pluralize(words_added)} imported."
      else
        "#{words_added} new #{"word".pluralize(words_added)} imported, #{words_already_exist} #{"word".pluralize(words_already_exist)} already #{"exist".pluralize(words_added)}."
      end
    redirect_to in_out_user_path(@current_user)
  rescue InvalidDateOrTime => error
    redirect_to import_words_path, alert: "Some words were unable to be imported: invalid date format: '#{error.message}'. Please use 'mm/dd/yyyy' formatted dates."
  end

  def download
    csv = CSV.generate(headers: true) do |csv|
      csv << ORDERED_CSV_FIELDS # add headers

      words = @current_user.words.order(added_to_list_at: :asc).order(created_at: :asc)
      words = words.cards_not_created if params[:filter] == "cards_not_created"

      # manually grabbing ids to use in batch because `.find_each` does not respect ordering by a custom field
      word_ids = words.pluck(:id)
      word_ids.each_slice(WORD_BATCH_SIZE) do |word_ids_batch|
        # refrencing the same words ActiveRelation here to keep our other sorting and where clauses
        words.where(id: word_ids_batch).each do |word|
          csv << ORDERED_CSV_FIELDS.map { |attr| word.send(attr) }
        end
      end
    end

    respond_to do |format|
      format.csv { send_data(csv, filename: "words_export_#{Time.now.utc.to_i}.csv") }
    end
  end

  private

  def set_word
    @word = @current_user.words.find(params[:id] || params[:word_id])
  end

  def word_params
    prepared_params = params
      .require(:word)
      .permit(:japanese, :english, :source_name, :source_reference, :note, :cards_created, :cards_created_at)
      .reject { |_, value| value.blank? }
      .each_value { |value| value.try(:strip!) }

    if prepared_params[:cards_created_at].present?
      prepared_params.merge({ cards_created_at: date_or_time_from(prepared_params[:cards_created_at]) })
    else
      prepared_params
    end
  end

  def filter_params
    params
      .permit(:filter, :search, :page, :order)
      .each_value { |value| value.try(:strip!) }
  end
end
