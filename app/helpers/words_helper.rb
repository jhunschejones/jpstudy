module WordsHelper
  def english_with_only_letters(word)
    word.english.gsub(/[^\w\s]/, "").strip
  end

  def filter_params_plus(additional_param_hash)
    raise "param hash required" unless additional_param_hash.is_a? Hash
    filter_params.merge(additional_param_hash)
  end

  def filter_params_minus(additional_param)
    raise "symbol param name required" unless additional_param.is_a? Symbol
    filter_params.except(additional_param)
  end

  def use_turbo_for_word_form?
    # `request.referrer` is `nil` when we're on a normal form page and it has a
    # url when we've dropped the form onto another page using Turbo.
    return false unless request.referrer.present?

    return true if request.referrer.split("?").first == words_url # always use Turbo on the word list page, irregardless of query params
    return false if defined?(@word) && @word.id.nil? # do not use Turbo on the plain, new word page
    return true if defined?(@word) && request.referrer == word_url(@word) # use Turbo on the word show page

    # Don't use turbo if we got to the form some other way
    return false
  end

  private

  def filter_params
    params
      .to_unsafe_hash
      .slice(:search, :filter, :order)
      .each_value { |value| value.try(:strip!) }
  end
end
