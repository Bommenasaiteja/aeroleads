require "test_helper"

class TwilioWebhooksControllerTest < ActionDispatch::IntegrationTest
  test "should get status_callback" do
    get twilio_webhooks_status_callback_url
    assert_response :success
  end
end
