module WordsHelper
  def filter_params_plus(additional_param_hash)
    raise "param hash required" unless additional_param_hash.is_a? Hash
    filter_params.merge(additional_param_hash)
  end

  def filter_params_minus(additional_param)
    raise "symbol param name required" unless additional_param.is_a? Symbol
    filter_params.except(additional_param)
  end

  private

  def filter_params
    params.to_unsafe_hash.slice(:search, :filter).each_value { |value| value.try(:strip!) }
  end
end
