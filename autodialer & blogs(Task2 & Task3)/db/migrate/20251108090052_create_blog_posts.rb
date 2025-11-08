class CreateBlogPosts < ActiveRecord::Migration[7.1]
  def change
    create_table :blog_posts do |t|
      t.string :title
      t.text :content
      t.string :author
      t.datetime :published_at

      t.timestamps
    end
  end
end
