class SubscriptionSerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize?(argument)
    argument.is_a?(Subscription)
  end

  def serialize(subscription)
    super(
      "id" => subscription.id,
      "start_date" => subscription.start_date,
      "next_charge_date" => subscription.next_charge_date,
      "status" => subscription.status,
      "buyer_self_management_token" => subscription.buyer_self_management_token
    )
  end

  def deserialize(props)
    Subscription.new(props.with_indifferent_access)
  end
end
