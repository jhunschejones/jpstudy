require "csv"

class KanjiController < ApplicationController
  include DateParsing

  ORDERED_CSV_FIELDS = [:character, :status, :added_to_list_on]
  KANJI_BATCH_SIZE = 1000
  READ_ACTIONS = [:next, :wall, :export, :download]

  before_action :secure_behind_subscription # except: READ_ACTIONS # Turn on for public resource feature
  before_action ->{ protect_user_scoped_read_actions_for(:kanji) }, only: READ_ACTIONS
  before_action :protect_user_scoped_modify_actions, except: READ_ACTIONS

  def next
    @next_kanji = Kanji.next_new_for(user: @resource_owner)
    @previous_kanji = @resource_owner.kanji
      .skipped_or_added
      .order(updated_at: :desc)
      .order(created_at: :asc)
      .first
    @as_seen_in_words =
      if @next_kanji.nil?
        []
      else
        @resource_owner
          .words
          .where("japanese ILIKE :character", character: "%#{@next_kanji.character}%")
      end
  end

  def finder
  end

  def create
    if kanji_from_finder = @resource_owner.kanji.new_status.find_by(character: kanji_params[:character])
      kanji_from_finder.status = kanji_params[:status]
      kanji_from_finder.added_to_list_at = Time.now.utc
    end
    kanji = kanji_from_finder || Kanji.new(kanji_params.merge({ user: @resource_owner, added_to_list_at: Time.now.utc }))
    unless kanji.save
      flash[:alert] = "Unable to save kanji: #{kanji.errors.full_messages.join(", ")}"
    end
    # prevent message from showing on additional kanji added after goal is reached by returning false
    flash[:success] = @resource_owner.has_reached_daily_kanji_target? && "🎉 You reached your daily kanji target!"
    redirect_to next_kanji_path(@resource_owner)
  end

  def bulk_create
    if params[:text].size > 2000
      return redirect_to finder_kanji_path(@resource_owner), alert: "Max text size is 2000 characters."
    end

    found_kanji_characters = params[:text]
      .strip
      .split("")
      .uniq
      .select { |character| character =~ Kanji::KANJI_REGEX }

    new_count = 0
    already_exist_count = 0
    characters_unable_to_add = []
    found_kanji_characters.each do |character|
      if @resource_owner.kanji.find_by(character: character)
        already_exist_count += 1
      else
        new_kanji = @resource_owner.kanji.new(
          character: character,
          status: Kanji::NEW_STATUS
        )
        if new_kanji.save
          new_count += 1
        else
          characters_unable_to_add << character
        end
      end
    end

    if characters_unable_to_add.any?
      flash[:alert] = "#{new_count} new kanji added, #{already_exist_count} kanji already #{already_exist_count == 1 ? "exists" : "exist"}. Unable to add: #{characters_unable_to_add.join(", ")}"
      unless @resource_owner.can_add_more_kanji?
        flash[:alert] += " because you have reached your kanji limit."
      end
    else
      flash[:success] = "#{new_count} new kanji added, #{already_exist_count} kanji already #{already_exist_count == 1 ? "exists" : "exist"}."
    end
    redirect_to finder_kanji_path(@resource_owner)
  end

  def update
    unless kanji_params[:status] == Kanji::NEW_STATUS
      return redirect_to next_kanji_path(@resource_owner), alert: "You may only update kanji back to a new status."
    end
    @kanji = @resource_owner.kanji.find(params[:id])
    flash[:hide_in_ms] = 1800
    flash[:notice] =
      case @kanji.status
      when Kanji::ADDED_STATUS
        "Kanji #{@kanji.character} is no longer marked as added."
      when Kanji::SKIPPED_STATUS
        "Kanji #{@kanji.character} is no longer marked as skipped."
      end
    @kanji.update!(status: kanji_params[:status], added_to_list_at: nil)
    redirect_to next_kanji_path(@resource_owner)
  end

  def destroy
    @kanji = @resource_owner.kanji.find(params[:id])
    @kanji.destroy
    if @kanji.status
      flash[:hide_in_ms] = 1800
      flash[:notice] =
        case @kanji.status
        when Kanji::ADDED_STATUS
          "Kanji #{@kanji.character} was removed from your list and is no longer marked as added."
        when Kanji::SKIPPED_STATUS
          "Kanji #{@kanji.character} was removed from your list and is no longer marked as skipped."
        end
    end
    redirect_to next_kanji_path(@resource_owner)
  end

  def import
  end

  def upload
    unless params[:csv_file]&.content_type == "text/csv"
      return redirect_to import_kanji_path(@resource_owner), alert: "Missing CSV file or unsupported file format"
    end

    kanji_added = 0
    kanji_updated = 0
    kanji_already_exist = 0
    CSV.read(params[:csv_file].path).each_with_index do |row, index|
      if index.zero?
        return redirect_to import_kanji_path(@resource_owner), alert: "Incorrectly formatted CSV" if row.size != ORDERED_CSV_FIELDS.size
        next if params[:csv_includes_headers]
      end

      character = row[0]
      status = row[1].downcase
      added_to_list_at = row[2].presence && date_or_time_from(row[2])

      if (kanji = Kanji.find_by(character: character, user: @resource_owner))
        if params[:overwrite_matching_kanji]
          kanji_updated += 1 if kanji.update(
            status: status,
            added_to_list_at: added_to_list_at,
            skip_turbostream_callbacks: true
          )
        end

        next kanji_already_exist += 1
      end

      kanji_added += 1 if Kanji.create(
        character: character,
        status: status,
        user: @resource_owner,
        added_to_list_at: added_to_list_at,
        skip_turbostream_callbacks: true
      )
    end

    unless @resource_owner.can_add_more_kanji?
      flash[:alert] = "You have reached your #{view_context.link_to("kanji limit", content_limits_path)}. Some new kanji may not have been added."
    end

    flash[:success] =
      if params[:overwrite_matching_kanji]
        "#{kanji_updated} existing kanji updated, #{kanji_added} new kanji imported."
      else
        "#{kanji_added} new kanji imported, #{kanji_already_exist} kanji already exist."
      end
    redirect_to in_out_user_path(@resource_owner)
  end

  def export
  end

  def download
    csv = CSV.generate(headers: true) do |csv|
      csv << ORDERED_CSV_FIELDS # add headers

      user_kanji = @resource_owner.kanji.order(added_to_list_at: :asc).order(created_at: :asc)

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
    # ⚠️ `delete_all` skips callbacks and returns the count of records affected
    destroyed_kanji_count = @resource_owner.kanji.delete_all
    redirect_to in_out_user_path(@resource_owner), success: "#{destroyed_kanji_count} kanji deleted."
  end

  def wall
    @all_added_characters = @resource_owner.kanji.added.pluck(:character)
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
