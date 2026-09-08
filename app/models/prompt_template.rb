class PromptTemplate < ApplicationRecord
  belongs_to :user, optional: true

  scope :available_to, ->(user) { where(user_id: [ nil, user.id ]) }

  validates :title, :category, :body, presence: true

  def official?
    user_id.nil? && user.nil?
  end
end
