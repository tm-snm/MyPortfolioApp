class PromptTemplatePreference < ApplicationRecord
  belongs_to :user
  belongs_to :prompt_template

  scope :favorites, -> { where(favorite: true) }
  scope :recently_used, -> {
    where.not(last_used_at: nil).order(last_used_at: :desc)
  }

  validates :prompt_template_id, uniqueness: { scope: :user_id }
end
