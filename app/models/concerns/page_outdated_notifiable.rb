module PageOutdatedNotifiable
  extend ActiveSupport::Concern

  TURBO_STREAM_DELAY = 2.seconds

  def notify_outdated_next_kanji_pages(async: true)
    raise ArgumentError unless user

    broadcast_args = {
      target: "page-outdated",
      partial: "page_outdated",
      locals: {
        visible: true,
        last_update: (Time.now - TURBO_STREAM_DELAY).utc,
        target_selector: ".next-kanji-page"
      }
    }

    if async
      broadcast_replace_later_to(user.kanji_stream_name, **broadcast_args)
    else
      broadcast_replace_to(user.kanji_stream_name, **broadcast_args)
    end
  end

  def notify_outdated_word_list_pages(async: true)
    raise ArgumentError unless id && user

    broadcast_args = {
      target: "page-outdated",
      partial: "page_outdated",
      locals: {
        visible: true,
        last_update: (Time.now - TURBO_STREAM_DELAY).utc,
        target_selector: ".word_#{id}"
      }
    }

    if async
      broadcast_replace_later_to(user.words_stream_name, **broadcast_args)
    else
      broadcast_replace_to(user.words_stream_name, **broadcast_args)
    end
  end
end
