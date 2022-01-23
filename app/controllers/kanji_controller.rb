require "csv"

class KanjiController < ApplicationController
  include DateParsing

  before_action :secure_behind_subscription

  ORDERED_CSV_FIELDS = [:character, :status, :added_to_list_on]
  KANJI_BATCH_SIZE = 1000

  def next
    @next_kanji = Kanji.next_new_for(user: @current_user)
    @previous_kanji = @current_user.kanji.order(created_at: :asc).last
    @as_seen_in_words =
      if @next_kanji.nil?
        []
      else
        @current_user
          .words
          .where("japanese ILIKE :character", character: "%#{@next_kanji.character}%")
      end
  end

  def create
    kanji = Kanji.new(kanji_params.merge({
      user: @current_user,
      added_to_list_at: Time.now.utc
    }))
    unless kanji.save
      flash[:alert] = "Unable to save kanji: #{kanji.errors.full_messages.join(", ")}"
    end
    # prevent message from showing on additional kanji added after goal is reached by returning false
    flash[:success] = @current_user.has_reached_daily_kanji_target? && "🎉 You reached your daily kanji target!"
    redirect_to next_kanji_path
  end

  def destroy
    @kanji = @current_user.kanji.find(params[:id])
    @kanji.destroy
    if @kanji.status
      flash[:notice] =
        case @kanji.status
        when Kanji::ADDED_STATUS
          "Kanji #{@kanji.character} was removed from your list and is no longer marked as added."
        when Kanji::SKIPPED_STATUS
          "Kanji #{@kanji.character} was removed from your list and is no longer marked as skipped."
        end
    end
    redirect_to next_kanji_path
  end

  def import
  end

  def upload
    unless params[:csv_file]&.content_type == "text/csv"
      return redirect_to import_kanji_path, alert: "Missing CSV file or unsupported file format"
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
      added_to_list_at = row[2].presence && date_or_time_from(row[2])

      if (kanji = Kanji.find_by(character: character, user: @current_user))
        if params[:overwrite_matching_kanji]
          kanji_updated += 1 if kanji.update(
            status: status,
            added_to_list_at: added_to_list_at
          )
        end

        next kanji_already_exist += 1
      end

      kanji_added += 1 if Kanji.create(
        character: character,
        status: status,
        user: @current_user,
        added_to_list_at: added_to_list_at
      )
    end

    if @current_user.has_reached_kanji_limit?
      flash[:alert] = "You have reached your #{view_context.link_to("kanji limit", content_limits_path)}. Some new kanji may not have been added."
    end

    flash[:success] =
      if params[:overwrite_matching_kanji]
        "#{kanji_updated} existing kanji updated, #{kanji_added} new kanji imported."
      else
        "#{kanji_added} new kanji imported, #{kanji_already_exist} kanji already exist."
      end
    redirect_to in_out_user_path(@current_user)
  end

  def export
  end

  def download
    csv = CSV.generate(headers: true) do |csv|
      csv << ORDERED_CSV_FIELDS # add headers

      user_kanji = @current_user.kanji.order(added_to_list_at: :asc).order(created_at: :asc)

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

  def destroy_all
    destroyed_kanji_count = @current_user.kanji.destroy_all.size
    redirect_to in_out_user_path(@current_user), success: "#{destroyed_kanji_count} kanji deleted."
  end

  private

  def kanji_params
    params
      .require(:kanji)
      .permit(:character, :status, :user_id)
      .reject { |_, value| value.blank? }
      .each_value { |value| value.try(:strip!) }
  end
end
