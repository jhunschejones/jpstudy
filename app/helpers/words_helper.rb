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

    # brand new users can use a link in empty_words_message to get to the new
    # word form, and we want `cancel` to redirect back (plus the optimization
    # of turbo requests won't make as big a difference yet)
    return false if defined?(@word) && @word.id.nil? && @current_user.words.size.zero?

     # always use Turbo on the word list page in all other conditions, irregardless
     # of query params
    return true if request.referrer.split("?").first == words_url

    # do not use Turbo on the plain, new word page, if we've made it this far
    return false if defined?(@word) && @word.id.nil?

    # use Turbo on the word show page
    return true if defined?(@word) && request.referrer == word_url(@word)

    # Don't use turbo if we got to the form some other way
    false
  end

  def source_name_datalist_values
    return [] unless @current_user
    @current_user
      .words
      .distinct
      .where.not(source_name: nil)
      .order(:source_name)
      .pluck(:source_name)
  end

  private

  def filter_params
    params
      .to_unsafe_hash
      .slice(:search, :filter, :order, :source_name)
      .each_value { |value| value.try(:strip!) }
  end
end
