require "test_helper"

class PhoneNumbersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get phone_numbers_index_url
    assert_response :success
  end

  test "should get create" do
    get phone_numbers_create_url
    assert_response :success
  end

  test "should get upload" do
    get phone_numbers_upload_url
    assert_response :success
  end

  test "should get show" do
    get phone_numbers_show_url
    assert_response :success
  end
end
