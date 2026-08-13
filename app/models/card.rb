class Card < ApplicationRecord
  belongs_to :user

  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  enum :status, {
    normal: 0,
    review_later: 1
  }

  scope :search_by_keyword, ->(keyword) {
    escaped_keyword = sanitize_sql_like(keyword.to_s)
    pattern = "%#{escaped_keyword}%"

    where(
      "cards.title ILIKE :keyword OR cards.body ILIKE :keyword",
      keyword: pattern
    )
  }

  validates :title, presence: true
  validates :body, presence: true
end
