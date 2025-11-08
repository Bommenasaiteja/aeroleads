class HomeController < ApplicationController
  def index
    @total_numbers = PhoneNumber.count
    @pending_calls = PhoneNumber.pending.count
    @completed_calls = CallLog.successful.count
    @failed_calls = CallLog.failed.count
    @recent_calls = CallLog.includes(:phone_number).order(created_at: :desc).limit(10)
  end
end
