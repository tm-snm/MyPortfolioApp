class PromptTemplatePreference < ApplicationRecord
  belongs_to :user
  belongs_to :prompt_template

  scope :favorites, -> { where(favorite: true) }
  scope :recently_used, -> {
    where.not(last_used_at: nil).order(last_used_at: :desc)
  }

  validates :prompt_template_id, uniqueness: { scope: :user_id }

  validate :available_template

  private

  def available_template
    return unless user && prompt_template
    return if prompt_template.official? || prompt_template.user == user

    errors.add(:prompt_template, "は共通または自分のものを指定してください")
  end
end
