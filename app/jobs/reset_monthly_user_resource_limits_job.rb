class ResetMonthlyUserResourceLimitsJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      User.update!(
        audio_conversions_used_this_month: 0
      )
    end
  end
end
