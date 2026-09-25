class DashboardMetrics
  TOP_TAG_LIMIT = 5
  CARD_LIST_LIMIT = 5
  MONTH_COUNT = 6

  def initialize(cards:, tags:, reference_time: Time.current)
    @cards = cards
    @tags = tags
    @reference_time = reference_time.in_time_zone
  end

  def call
    {
      total_cards: @cards.count,
      cards_this_month: cards_this_month,
      review_scheduled_count: @cards.review_later.count,
      overdue_review_count: @cards.review_overdue_before(reference_date).count,
      top_tags: top_tags,
      recent_cards: recent_cards,
      low_understanding_cards: low_understanding_cards,
      monthly_card_counts: monthly_card_counts
    }
  end

  private

  def cards_this_month
    @cards.where(created_at: current_month_start...next_month_start).count
  end

  def current_month_start
    @reference_time.beginning_of_month
  end

  def next_month_start
    current_month_start.next_month
  end

  def reference_date
    @reference_time.to_date
  end

  def top_tags
    counts = @tags
             .joins(:taggings)
             .where(taggings: { card_id: @cards.select(:id) })
             .group("tags.id", "tags.name")
             .order(Arel.sql("COUNT(taggings.id) DESC"), name: :asc, id: :asc)
             .limit(TOP_TAG_LIMIT)
             .count("taggings.id")

    counts.map do |(id, name), count|
      { id: id, name: name, count: count }
    end
  end

  def recent_cards
    @cards.sorted_by("newest").limit(CARD_LIST_LIMIT).to_a
  end

  def low_understanding_cards
    @cards
      .understanding_level_not_understood
      .sorted_by("newest")
      .limit(CARD_LIST_LIMIT)
      .to_a
  end

  def monthly_card_counts
    months = month_starts
    counts = grouped_monthly_counts(months)

    months.map do |month|
      {
        month: month.to_date,
        count: counts.fetch(month.to_date, 0)
      }
    end
  end

  def month_starts
    (MONTH_COUNT - 1).downto(0).map do |months_ago|
      current_month_start - months_ago.months
    end
  end

  def grouped_monthly_counts(months)
    @cards
      .where(created_at: months.first...months.last.next_month)
      .group(month_group_expression)
      .count
      .transform_keys(&:to_date)
  end

  def month_group_expression
    quoted_time_zone = @cards.klass.connection.quote(Time.zone.tzinfo.name)

    Arel.sql(
      "DATE_TRUNC('month', cards.created_at AT TIME ZONE 'UTC' " \
      "AT TIME ZONE #{quoted_time_zone})"
    )
  end
end
