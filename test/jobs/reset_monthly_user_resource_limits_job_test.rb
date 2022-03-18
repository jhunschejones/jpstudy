require "test_helper"

class ResetMonthlyUserResourceLimitsJobTest < ActiveJob::TestCase
  it "sets audio_conversions_used_this_month to 0 for all users" do
    users(:carl).update!(audio_conversions_used_this_month: 5)
    ResetMonthlyUserResourceLimitsJob.perform_now
    assert_equal 0, users(:carl).reload.audio_conversions_used_this_month
  end
end
