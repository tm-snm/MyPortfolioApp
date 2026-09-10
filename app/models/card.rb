class Card < ApplicationRecord
  belongs_to :user

  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  SEARCH_TARGETS = %w[all title body].freeze
  SORT_ORDERS = %w[newest oldest].freeze
  REVIEW_FILTERS = %w[all due today this_week overdue].freeze

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

  scope :review_due_by, ->(date) {
    review_later.where(next_review_on: ..date)
  }
  scope :review_due_on, ->(date) {
    review_later.where(next_review_on: date)
  }
  scope :review_due_between, ->(from, to) {
    review_later.where(next_review_on: from..to)
  }
  scope :review_overdue_before, ->(date) {
    review_later.where("next_review_on < ?", date)
  }

  validates :title, presence: true
  validates :body, presence: true
  validates :next_review_on,
            presence: true,
            comparison: { greater_than_or_equal_to: -> { Date.current } },
            on: :review_scheduling

  def schedule_review(next_review_on:)
    assign_attributes(
      status: :review_later,
      next_review_on: next_review_on
    )
    save_review_schedule
  end

  def mark_reviewed(next_review_on:, reviewed_at: Time.current)
    assign_attributes(
      status: :review_later,
      next_review_on: next_review_on,
      last_reviewed_at: reviewed_at
    )
    save_review_schedule
  end

  def cancel_review
    update(status: :normal, next_review_on: nil)
  end

  def review_timing(today: Date.current)
    return :none unless review_later?
    return :unscheduled if next_review_on.blank?
    return :overdue if next_review_on < today
    return :today if next_review_on == today
    return :this_week if next_review_on <= today.end_of_week

    :later
  end

  private

  def save_review_schedule
    return true if save(context: :review_scheduling)

    restore_attributes
    false
  end
end
