class Card < ApplicationRecord
  belongs_to :user

  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  enum :status, {
    normal: 0,
    review_later: 1
  }

  validates :title, presence: true
  validates :body, presence: true
end
