desc "Reset monthly user resource limits"
task reset_monthly_user_resource_limits: [:environment] do
  first_of_the_month = Date.today.beginning_of_month
  cache_key = "monthly_user_limits_reset_on_#{first_of_the_month}"

  if first_of_the_month == Date.today
    if Rails.cache.read(cache_key)
      Rails.logger.info("Skipping ResetMonthlyUserResourceLimitsJob job because it was already run todays")
    else
      Rails.logger.info("Enqueueing ResetMonthlyUserResourceLimitsJob job...")
      ResetMonthlyUserResourceLimitsJob.perform_later
      Rails.cache.write(cache_key, Time.now.to_s, expires_in: 2.days)
    end
  else
    Rails.logger.info("Skipping ResetMonthlyUserResourceLimitsJob job until the 1st of the month")
  end
end
