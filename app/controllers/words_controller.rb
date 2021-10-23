class WordsController < ApplicationController
  before_action :set_word, only: %i[ show edit update destroy ]

  # GET /words
  def index
    @words = Word.all
  end

  # GET /words/1
  def show
  end

  # GET /words/new
  def new
    @word = Word.new
  end

  # GET /words/1/edit
  def edit
  end

  # POST /words
  def create
    @word = Word.new(word_params)

    if @word.save
      redirect_to @word, notice: "Word was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /words/1
  def update
    if @word.update(word_params)
      redirect_to @word, notice: "Word was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /words/1
  def destroy
    @word.destroy
    redirect_to words_url, notice: "Word was successfully destroyed."
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_word
    @word = Word.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def word_params
    params
      .require(:word)
      .permit(:japanese, :english, :source_name, :cards_created_on)
  end
end
