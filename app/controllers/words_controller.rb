class WordsController < ApplicationController
  before_action :set_word, only: %i[ show edit update destroy toggle_card_created ]

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
    redirect_to words_url, notice: "Word was successfully destroyed."
  end

  def toggle_card_created
    if @word.cards_created?
      @word.update!(cards_created: false)
    else
      @word.update!(cards_created: true)
    end
    redirect_to @word
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
end
