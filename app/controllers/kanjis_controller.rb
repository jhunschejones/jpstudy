class KanjisController < ApplicationController
  before_action :set_kanji, only: %i[ show edit update destroy ]

  # GET /kanjis
  def index
    @kanjis = Kanji.all
  end

  # GET /kanjis/1
  def show
  end

  # GET /kanjis/new
  def new
    @kanji = Kanji.new
  end

  # GET /kanjis/1/edit
  def edit
  end

  # POST /kanjis
  def create
    @kanji = Kanji.new(kanji_params)

    if @kanji.save
      redirect_to @kanji, notice: "Kanji was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /kanjis/1
  def update
    if @kanji.update(kanji_params)
      redirect_to @kanji, notice: "Kanji was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /kanjis/1
  def destroy
    @kanji.destroy
    redirect_to kanjis_url, notice: "Kanji was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_kanji
      @kanji = Kanji.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def kanji_params
      params.require(:kanji).permit(:character, :status, :user_id)
    end
end
