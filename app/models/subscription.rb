class Subscription

  attr_reader :id, :start_date, :next_charge_date, :status, :buyer_self_management_token

  def initialize(props)
    @id = props[:id]
    @start_date = Time.parse(props[:start_date])
    @next_charge_date = Time.parse(props[:charged_through_date])
    @status = props[:status]
    @buyer_self_management_token = props[:buyer_self_management_token]
  end

  def self_management_link
    "https://squareup.com/buyer-subscriptions/manage?buyer_management_token=#{@buyer_self_management_token}"
  end

  def active?
    @status == "ACTIVE"
  end
end
