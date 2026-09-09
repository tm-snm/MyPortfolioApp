class PromptTemplate < ApplicationRecord
  belongs_to :user, optional: true
  has_many :prompt_template_preferences, dependent: :destroy

  scope :available_to, ->(user) { where(user_id: [ nil, user.id ]) }
  scope :favorited_by, ->(user) {
    joins(:prompt_template_preferences)
      .merge(user.prompt_template_preferences.favorites)
  }
  scope :recently_used_by, ->(user) {
    joins(:prompt_template_preferences)
      .merge(user.prompt_template_preferences.recently_used)
  }

  validates :title, :category, :body, presence: true

  def official?
    user_id.nil? && user.nil?
  end
end
