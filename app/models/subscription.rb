class Subscription

  attr_reader :id, :start_date, :next_charge_date

  def initialize(props)
    @id = props[:id]
    @start_date = props[:start_date]
    @next_charge_date = props[:charged_through_date]
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
