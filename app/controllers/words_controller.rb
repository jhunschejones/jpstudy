require "csv"

class WordsController < ApplicationController
  before_action :set_word, only: [:show, :edit, :update, :destroy, :toggle_card_created]

  def index
    @words = Word.order(created_at: :desc)
  end

  def show
  end

  def new
    @word = Word.new
  end

  def edit
  end

  def create
    @word = Word.new(word_params)

    if @word.save
      redirect_to words_url, notice: "Word was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @word.update(word_params)
      redirect_to @word, notice: "Word was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @word.destroy
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.remove(@word)
      }
      format.html {
        redirect_to words_url, notice: "Word was successfully destroyed."
      }
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

  def upload
    unless params[:csv_file]&.content_type == "text/csv"
      return redirect_to import_words_path, notice: "Unsupported file format"
    end

    CSV.read(params[:csv_file].path).each_with_index do |row, index|
      next if index.zero? && params[:csv_includes_headers]

      english = row[params[:english].to_i - 1]
      japanese = row[params[:japanese].to_i - 1]
      next unless english && japanese

      Word.find_or_create_by(
        english: english,
        japanese: japanese,
        source_name: params[:source_name],
        source_reference: params[:source_reference].to_i.zero? ? nil : row[params[:source_reference].to_i - 1],
        cards_created: index < params[:last_created_card_row].to_i, # the value submitted by the client is one past the actual row index
        created_at: params[:created_at].to_i.zero? ? nil : word_created_time(row[params[:created_at].to_i - 1])
      )
    end

    redirect_to words_url, notice: "Words successfully imported."
  end

  private

  def set_word
    @word = Word.find(params[:id] || params[:word_id])
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
