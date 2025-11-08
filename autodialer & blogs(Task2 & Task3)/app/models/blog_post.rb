class BlogPost < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true
  validates :author, presence: true
  
  scope :published, -> { where.not(published_at: nil) }
  scope :draft, -> { where(published_at: nil) }
  
  def published?
    published_at.present?
  end
  
  def publish!
    update(published_at: Time.current)
  end
end
