desc "Reset monthly user resource limits"
task reset_monthly_user_resource_limits: [:environment] do
  ResetMonthlyUserResourceLimitsJob.perform_later
end
