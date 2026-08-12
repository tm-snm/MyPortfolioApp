class Tagging < ApplicationRecord
  belongs_to :card
  belongs_to :tag

  validates :tag_id,
            uniqueness: { scope: :card_id }
end
