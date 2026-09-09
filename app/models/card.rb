class Card < ApplicationRecord
  belongs_to :user

  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  SEARCH_TARGETS = %w[all title body].freeze
  SORT_ORDERS = %w[newest oldest].freeze

  enum :status, {
    normal: 0,
    review_later: 1
  }

  scope :search_by_keyword, ->(keyword, target = "all") {
    escaped_keyword = sanitize_sql_like(keyword.to_s)
    pattern = "%#{escaped_keyword}%"

    condition =
      case target.to_s
      when "title"
        "cards.title ILIKE :keyword"
      when "body"
        "cards.body ILIKE :keyword"
      else
        "cards.title ILIKE :keyword OR cards.body ILIKE :keyword"
      end

    where(condition, keyword: pattern)
  }

  scope :matching_title, ->(keyword) {
    escaped_keyword = sanitize_sql_like(keyword.to_s)
    where("cards.title ILIKE :keyword", keyword: "%#{escaped_keyword}%")
  }

  scope :sorted_by, ->(sort_order) {
    direction = sort_order.to_s == "oldest" ? :asc : :desc
    order(created_at: direction, id: direction)
  }

  scope :tagged_with, ->(tag_id) {
    joins(:tags)
      .where(tags: { id: tag_id })
      .distinct
  }

  validates :title, presence: true
  validates :body, presence: true
end
