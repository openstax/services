class MessageBody < ApplicationRecord
  belongs_to :message, inverse_of: :body

  validates_presence_of :message
  validates_uniqueness_of :message_id, allow_nil: true
  validate :not_empty

  protected

  def not_empty
    return unless [html, text, short_text].all?{|f| f.blank?}
    errors.add(:base, :blank)
    false
  end
end
