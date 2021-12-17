class KanjiController < ApplicationController
  before_action :secure_behind_subscription

  ORDERED_CSV_FIELDS = [
    :character,
    :status
  ]
  KANJI_BATCH_SIZE = 1000

  def next
  end

  def import
  end

  def upload
    unless params[:csv_file]&.content_type == "text/csv"
      return redirect_to import_words_path, alert: "Missing CSV file or unsupported file format"
    end

    kanji_added = 0
    kanji_updated = 0
    kanji_already_exist = 0
    CSV.read(params[:csv_file].path).each_with_index do |row, index|
      if index.zero?
        return redirect_to import_kanji_path, alert: "Incorrectly formatted CSV" if row.size != ORDERED_CSV_FIELDS.size
        next if params[:csv_includes_headers]
      end

      character = row[0]
      status = row[1].downcase

      if (kanji = Kanji.find_by(character: character, user: @current_user))
        if params[:overwrite_matching_kanji]
          kanji_updated += 1 if kanji.update(status: status)
        end

        next kanji_already_exist += 1
      end

      kanji_added += 1 if Kanji.create(
        character: character,
        status: status,
        user: @current_user
      )
    end

    # TODO: add kanji limit functionality
    # if @current_user.has_reached_kanji_limit?
    #   flash[:alert] = "You have reached your #{view_context.link_to("kanji limit", kanji_limit_path)}. Some new kanji may not have been added."
    # end

    flash[:success] =
      if params[:overwrite_matching_kanji]
        "#{kanji_updated} existing kanji updated, #{kanji_added} new kanji imported."
      else
        "#{kanji_added} new kanji imported, #{words_already_exist} kanji already #{"exist".pluralize(kanji_added)}."
      end
    redirect_to in_out_user_path(@current_user)
  end

  def export
  end

  def download
    csv = CSV.generate(headers: true) do |csv|
      csv << ORDERED_CSV_FIELDS # add headers

      user_kanji = @current_user.kanji.order(created_at: :asc)

      # manually grabbing ids to use in batch because `.find_each` does not respect ordering by a custom field
      kanji_ids = user_kanji.pluck(:id)
      kanji_ids.each_slice(KANJI_BATCH_SIZE) do |kanji_ids_batch|
        # refrencing the same user_kanji ActiveRelation here to keep our other sorting and where clauses
        user_kanji.where(id: kanji_ids_batch).each do |kanji|
          csv << ORDERED_CSV_FIELDS.map { |attr| kanji.send(attr) }
        end
      end
    end

    respond_to do |format|
      format.csv { send_data(csv, filename: "kanji_export_#{Time.now.utc.to_i}.csv") }
    end
  end

  private

  def kanji_params
    params.require(:kanji).permit(:character, :status, :user_id)
  end
end
