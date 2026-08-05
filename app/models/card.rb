class Card < ApplicationRecord
  belongs_to :user

  enum :status, {
    normal: 0,
    review_later: 1
  }

  validates :title, presence: true
  validates :body, presence: true
end
