class Tagging < ApplicationRecord
  belongs_to :card
  belongs_to :tag

  validates :tag_id,
            uniqueness: { scope: :card_id }

  validate :matching_owners

  private

  def matching_owners
    return unless card && tag
    return if card.user == tag.user

    errors.add(:tag, "はカードと同じユーザーのものを指定してください")
  end
end
