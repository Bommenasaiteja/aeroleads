class CallLog < ApplicationRecord
  belongs_to :phone_number
  
  validates :status, inclusion: { in: %w[initiated ringing answered completed busy no-answer failed] }
  
  scope :successful, -> { where(status: %w[answered completed]) }
  scope :failed, -> { where(status: %w[busy no-answer failed]) }
  
  def successful?
    %w[answered completed].include?(status)
  end
  
  def failed?
    %w[busy no-answer failed].include?(status)
  end
end
