class PhoneNumber < ApplicationRecord
  has_many :call_logs, dependent: :destroy
  
  validates :number, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending called failed] }
  
  scope :pending, -> { where(status: 'pending') }
  scope :called, -> { where(status: 'called') }
  scope :failed, -> { where(status: 'failed') }
  
  def self.page_by_status
    order(:status, :created_at)
  end
  
  def self.upload_from_text(text_content)
    numbers = text_content.split(/[,\n\r]+/).map(&:strip).reject(&:blank?)
    numbers.each do |number|
      create(number: number, status: 'pending', uploaded_at: Time.current)
    end
  end
end
