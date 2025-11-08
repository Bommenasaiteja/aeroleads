require "test_helper"

class BlogPostsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get blog_posts_index_url
    assert_response :success
  end

  test "should get show" do
    get blog_posts_show_url
    assert_response :success
  end

  test "should get create" do
    get blog_posts_create_url
    assert_response :success
  end

  test "should get new" do
    get blog_posts_new_url
    assert_response :success
  end
end
