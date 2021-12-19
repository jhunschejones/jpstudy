module DateParsing
  extend ActiveSupport::Concern

  class InvalidDateOrTime < StandardError; end

  def date_or_time_from(time_or_date_string)
    # === Attempt to parse a date ===
    if time_or_date_string.is_a?(String)
      begin
        if time_or_date_string.split("/").last.size == 4
          return Date.strptime(time_or_date_string, "%m/%d/%Y")
        end
        return Date.strptime(time_or_date_string, "%m/%d/%y")
      rescue Date::Error
      end
    end

    # === Attempt to parse a time ===
    begin
      if time_or_date_string.is_a?(String)
        return Time.parse(time_or_date_string)
      end
      if time_or_date_string.is_a?(Integer)
        return Time.at(time_or_date_string)
      end
    rescue ArgumentError, TypeError
    end

    raise InvalidDateOrTime.new(time_or_date_string)
  end
end
