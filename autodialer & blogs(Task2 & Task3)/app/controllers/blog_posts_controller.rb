class BlogPostsController < ApplicationController
  before_action :set_blog_post, only: [:show]
  
  def index
    @blog_posts = BlogPost.published.order(published_at: :desc)
    @recent_posts = @blog_posts.limit(10)
  end

  def show
  end

  def new
    @blog_post = BlogPost.new
  end

  def create
    @blog_post = BlogPost.new(blog_post_params)
    @blog_post.author = "Autodialer Admin"
    
    if @blog_post.save
      @blog_post.publish!
      redirect_to blog_post_path(@blog_post), notice: 'Blog post created successfully!'
    else
      render :new
    end
  end

  def generate_ai_posts
    titles_with_descriptions = params[:titles_list]
    
    if titles_with_descriptions.blank?
      redirect_to new_blog_post_path, alert: 'Please provide titles for blog posts'
      return
    end

    begin
      openai_service = OpenaiService.new
      generated_count = 0
      
      titles_with_descriptions.split("\n").each do |line|
        line = line.strip
        next if line.blank?
        
        # Parse title and description (format: "Title - Description" or just "Title")
        parts = line.split(' - ', 2)
        title = parts[0].strip
        description = parts[1]&.strip || ""
        
        next if title.blank?
        
        # Generate content using AI
        content = openai_service.generate_blog_post(title, description)
        
        if content.present?
          blog_post = BlogPost.create!(
            title: title,
            content: content,
            author: "AI Assistant",
            published_at: Time.current
          )
          generated_count += 1
        end
        
        sleep(1) # Rate limiting for API calls
      end
      
      redirect_to blog_posts_path, notice: "Successfully generated #{generated_count} blog posts!"
    rescue => e
      Rails.logger.error "Blog generation error: #{e.message}"
      redirect_to new_blog_post_path, alert: "Error generating posts: #{e.message}"
    end
  end

  private

  def set_blog_post
    @blog_post = BlogPost.find(params[:id])
  end

  def blog_post_params
    params.require(:blog_post).permit(:title, :content)
  end
end
