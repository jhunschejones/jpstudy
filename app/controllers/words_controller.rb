require "csv"

class WordsController < ApplicationController
  include DateParsing

  ORDERED_CSV_FIELDS = [:english, :japanese, :source_name, :source_reference,
    :starred, :checked, :checked_on, :added_to_list_on, :note]
  CSV_CONTENT_TYPE = "text/csv"
  TRUTHY_CSV_VALUES = ["true", "t", "x", "yes", "y"]
  WORDS_PER_PAGE = 10
  MAX_SEARCH_LENGTH = 30
  WORD_BATCH_SIZE = 1000
  READ_ACTIONS = [:index, :count, :show, :search, :export, :download]

  before_action :secure_behind_subscription # except: READ_ACTIONS # Turn on for public resource feature
  before_action ->{ protect_user_scoped_read_actions_for(:words) }, only: READ_ACTIONS
  before_action :protect_user_scoped_modify_actions, except: READ_ACTIONS
  before_action :set_word, only: [:show, :edit, :update, :destroy, :toggle_checked, :toggle_starred]

  def index
    @page = filter_params[:page] ? filter_params[:page].to_i : 1 # force pagination to conserve memory
    @offset = (@page - 1) * WORDS_PER_PAGE
    @order = filter_params[:order] == "oldest_first" ? :asc : :desc

    @words = @resource_owner.words.includes(:user).order(added_to_list_at: @order).order(created_at: @order)
    if filter_params[:search]
      @words = @words.where("english ILIKE :search OR japanese ILIKE :search", search: "%#{filter_params[:search][0..MAX_SEARCH_LENGTH - 1]}%")
    end
    if filter_params[:checked] == "false"
      @words = @words.not_checked
    end
    if filter_params[:starred] == "true"
      @words = @words.where(starred: true)
    end
    if filter_params[:source_name]
      @words = @words.where("source_name ILIKE :source_name", source_name: "%#{filter_params[:source_name][0..MAX_SEARCH_LENGTH - 1]}%")
    end

    @matching_words_count = @words.count
    @words = @words.offset(@offset).limit(WORDS_PER_PAGE)
    # Calling `.to_a` at the end here executes the query before calling `.size`. If we don't do it in
    # this order, an extra SQL COUNT query gets run here before the Word Load query.
    @next_page = @page + 1 if @words.to_a.size == WORDS_PER_PAGE
  end

  def count
    @words = @resource_owner.words
    if filter_params[:search]
      @words = @words.where("english ILIKE :search OR japanese ILIKE :search", search: "%#{filter_params[:search][0..MAX_SEARCH_LENGTH - 1]}%")
    end
    if filter_params[:checked] == "false"
      @words = @words.not_checked
    end
    if filter_params[:starred] == "true"
      @words = @words.where(starred: true)
    end
    if filter_params[:source_name]
      @words = @words.where("source_name ILIKE :source_name", source_name: "%#{filter_params[:source_name][0..MAX_SEARCH_LENGTH - 1]}%")
    end

    render json: { "wordsCount" => @words.count }.to_json
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
      flash[:hide_in_ms] = 1200
      respond_to do |format|
        format.turbo_stream { flash.now[:success] = "'#{@word.japanese}' was successfully created." }
        format.html { redirect_to words_url, success: "'#{@word.japanese}' was successfully created." }
      end
    else
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "Unable to create word: #{@word.errors.full_messages.join(", ")}" }
        format.html { redirect_to new_word_path(@current_user), notice: "Unable to create word: #{@word.errors.full_messages.join(", ")}" }
      end
    end
  end

  def update
    if @word.update(word_params)
      flash[:hide_in_ms] = 1800
      respond_to do |format|
        format.turbo_stream { flash.now[:success] = "'#{@word.japanese}' was successfully updated." }
        format.html { redirect_to word_path(@current_user, @word), success: "'#{@word.japanese}' was successfully updated." }
      end
    else
      flash[:notice] = "Unable to update word: #{@word.errors.full_messages.map(&:downcase).join(", ")}"
      redirect_to edit_word_path(@current_user, @word)
    end
  end

  def destroy
    @word.destroy
    flash[:hide_in_ms] = 1800
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = "'#{@word.japanese}' was successfully deleted." }
      format.html { redirect_to words_path(@current_user), notice: "'#{@word.japanese}' was successfully deleted." }
    end
  end

  def destroy_all
    # ⚠️ `delete_all` skips callbacks and returns the count of records affected
    destroyed_words_count = @current_user.words.delete_all
    redirect_to in_out_user_path(@current_user), success: "#{destroyed_words_count} #{"word".pluralize(destroyed_words_count)} deleted."
  end

  def toggle_checked
    if @word.checked?
      @word.update!(checked: false, checked_at: nil)
    else
      @word.update!(checked: true, checked_at: Time.now.utc)
    end
    # prevent message from showing on additional words added after goal is reached by returning false
    daily_target_message = @current_user.has_reached_daily_word_target? && "🎉 You reached your daily word target!"
    respond_to do |format|
      format.turbo_stream { flash.now[:success] = daily_target_message }
      format.html {
        flash[:success] = daily_target_message
        redirect_to word_path(@current_user, @word)
      }
    end
  end

  def toggle_starred
    @word.update!(starred: !@word.starred?)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to word_path(@current_user, @word) }
    end
  end

  def import
  end

  def export
  end

  def upload
    unless params[:csv_file]&.content_type == CSV_CONTENT_TYPE
      return redirect_to import_words_path(@current_user), alert: "Missing CSV file or unsupported file format"
    end

    words_added = 0
    words_updated = 0
    words_already_exist = 0
    CSV.read(params[:csv_file].path).each_with_index do |row, index|
      if index.zero?
        return redirect_to import_words_path(@current_user), alert: "Incorrectly formatted CSV" if row.size != ORDERED_CSV_FIELDS.size
        next if params[:csv_includes_headers]
      end

      english = row[0]
      japanese = row[1]
      source_name = row[2].presence
      source_reference = row[3].presence
      starred = TRUTHY_CSV_VALUES.include?(row[4]&.downcase)
      checked = TRUTHY_CSV_VALUES.include?(row[5]&.downcase)
      checked_at = row[6].presence && date_or_time_from(row[6])
      added_to_list_at = row[7].presence && date_or_time_from(row[7])
      note = row[8].presence

      if (word = Word.find_by(english: english, japanese: japanese, user: @current_user))
        if params[:overwrite_matching_words]
          words_updated += 1 if word.update(
            source_name: source_name,
            source_reference: source_reference,
            starred: starred,
            checked: checked,
            checked_at: checked_at,
            added_to_list_at: added_to_list_at,
            note: note,
            skip_turbostream_callbacks: true
          )
        end

        next words_already_exist += 1
      end

      words_added += 1 if Word.create(
        english: english,
        japanese: japanese,
        source_name: source_name,
        source_reference: source_reference,
        starred: starred,
        checked: checked,
        checked_at: checked_at,
        added_to_list_at: added_to_list_at,
        note: note,
        user: @current_user,
        skip_turbostream_callbacks: true
      )
    end

    unless @current_user.can_add_more_words?
      flash[:alert] = "You have reached your #{view_context.link_to("word limit", content_limits_path)}. Some new words may not have been added."
    end

    flash[:success] =
      if params[:overwrite_matching_words]
        "#{words_updated} existing #{"word".pluralize(words_updated)} updated, #{words_added} new #{"word".pluralize(words_added)} imported."
      else
        "#{words_added} new #{"word".pluralize(words_added)} imported, #{words_already_exist} #{"word".pluralize(words_already_exist)} already #{words_already_exist == 1 ? "exists" : "exist"}."
      end
    redirect_to in_out_user_path(@current_user)
  rescue InvalidDateOrTime => error
    redirect_to import_words_path(@current_user), alert: "Some words were unable to be imported: invalid date format: '#{error.message}'. Please use 'mm/dd/yyyy' formatted dates."
  end

  def download
    only_not_checked_words = params[:checked] == "false"
    csv = CSV.generate(headers: true) do |csv|
      csv << ORDERED_CSV_FIELDS # add headers

      words = @current_user.words.order(added_to_list_at: :asc).order(created_at: :asc)
      words = words.not_checked if only_not_checked_words

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
      .permit(:japanese, :english, :source_name, :source_reference, :note, :checked, :checked_at)
      .reject { |_, value| value.blank? }
      .each_value { |value| value.try(:strip!) }

    if prepared_params[:checked_at].present?
      prepared_params.merge({ checked_at: date_or_time_from(prepared_params[:checked_at]) })
    else
      prepared_params
    end
  end

  def filter_params
    params
      .permit(:checked, :search, :page, :order, :source_name, :starred)
      .each_value { |value| value.try(:strip!) }
  end
end
