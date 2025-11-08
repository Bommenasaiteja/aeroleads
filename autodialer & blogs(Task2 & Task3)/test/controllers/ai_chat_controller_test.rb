require "test_helper"

class AiChatControllerTest < ActionDispatch::IntegrationTest
  test "should get process" do
    get ai_chat_process_url
    assert_response :success
  end
end
