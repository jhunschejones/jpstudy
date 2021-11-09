require "csv"

class WordsController < ApplicationController
  before_action :secure_behind_subscription
  before_action :set_word, only: [:show, :edit, :update, :destroy, :toggle_card_created]

  def index
    @words = @current_user.words.order(created_at: :desc)
  end

  def show
  end

  def new
    @word = Word.new
  end

  def edit
  end

  def create
    @word = Word.new(word_params.merge({ user: @current_user }))

    if @word.save
      redirect_to words_url, success: "Word was successfully created."
    else
      flash[:notice] = "Unable to create word: #{@word.errors.full_messages.map(&:downcase).join(", ")}"
      redirect_to new_word_path
    end
  end

  def update
    if @word.update(word_params)
      respond_to do |format|
        format.turbo_stream { redirect_to @word }
        # only return flash if this is an HTML request
        format.html { redirect_to @word, success: "Word was successfully updated." }
      end
    else
      flash[:notice] = "Unable to update word: #{@word.errors.full_messages.map(&:downcase).join(", ")}"
      redirect_to edit_word_path(@word)
    end
  end

  def destroy
    @word.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@word) }
      format.html { redirect_to words_url, notice: "Word was successfully destroyed." }
    end
  end

  def toggle_card_created
    if @word.cards_created?
      @word.update!(cards_created: false)
    else
      @word.update!(cards_created: true)
    end
    redirect_to @word
  end

  def import
  end

  def export
  end

  def upload
    unless params[:csv_file]&.content_type == "text/csv"
      return redirect_to import_words_path, notice: "Unsupported file format"
    end

    words_added = 0
    words_already_exist = 0
    CSV.read(params[:csv_file].path).each_with_index do |row, index|
      next if index.zero? && params[:csv_includes_headers]

      english = row[params[:english].to_i - 1]
      japanese = row[params[:japanese].to_i - 1]
      next unless english && japanese

      if Word.find_by(english: english, japanese: japanese, user: @current_user)
        next words_already_exist += 1
      end

      words_added +=1 if Word.create(
        english: english, japanese: japanese,
        source_name: params[:source_name],
        source_reference: params[:source_reference].to_i.zero? ? nil : row[params[:source_reference].to_i - 1],
        cards_created: index < params[:last_created_card_row].to_i, # the value submitted by the client is one past the actual row index
        created_at: params[:created_at].to_i.zero? ? nil : word_created_time(row[params[:created_at].to_i - 1]),
        user: @current_user
      )
    end

    redirect_to words_url, success: "#{words_added} #{"word".pluralize(words_added)} successfully imported."
  end

  def download
    attributes = [:english, :japanese, :source_name, :source_reference, :cards_created, :added_on]

    csv = CSV.generate(headers: true) do |csv|
      csv << attributes

      @current_user.words.find_each do |word|
        csv << attributes.map { |attr| word.send(attr) }
      end
    end

    respond_to do |format|
      format.csv { send_data(csv, filename: "words_export.csv") }
    end
  end

  private

  def set_word
    @word = Word.find_by(user: @current_user, id: params[:id] || params[:word_id])
  end

  def word_params
    params
      .require(:word)
      .permit(:japanese, :english, :source_name, :source_reference, :cards_created)
  end

  def word_created_time(time_or_date_string)
    begin
      if time_or_date_string.size == 8
        return Date.strptime(time_or_date_string, "%m/%d/%y")
      elsif time_or_date_string.size == 10
        return Date.strptime(time_or_date_string, "%m/%d/%Y")
      end
    rescue Date::Error
    end
    begin
      return Time.parse(time_or_date_string)
    rescue ArgumentError
    end
    raise "Invalid created at time"
  end
end
