require "rails_helper"

RSpec.describe DashboardMetrics do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:reference_time) { Time.zone.local(2026, 9, 19, 12, 0) }

  subject(:metrics) do
    described_class.new(
      cards: user.cards,
      tags: user.tags,
      reference_time: reference_time
    ).call
  end

  around do |example|
    travel_to(reference_time) { example.run }
  end

  describe "#call" do
    it "カード数と復習状況を自分のカードだけから集計する" do
      create(
        :card,
        user: user,
        title: "今月の通常カード",
        created_at: Time.zone.local(2026, 9, 2, 10, 0)
      )
      create(
        :card,
        user: user,
        title: "前月の通常カード",
        created_at: Time.zone.local(2026, 8, 31, 23, 59)
      )
      create(
        :card,
        :scheduled_for_review,
        user: user,
        title: "期限超過カード",
        next_review_on: Date.current.yesterday,
        created_at: Time.zone.local(2026, 9, 3, 10, 0)
      )
      create(
        :card,
        :scheduled_for_review,
        user: user,
        title: "今日の復習カード",
        next_review_on: Date.current,
        created_at: Time.zone.local(2026, 9, 4, 10, 0)
      )
      create(
        :card,
        user: user,
        title: "復習日未設定カード",
        status: :review_later,
        created_at: Time.zone.local(2026, 9, 5, 10, 0)
      )
      create(
        :card,
        :scheduled_for_review,
        user: other_user,
        next_review_on: Date.current.yesterday,
        created_at: Time.zone.local(2026, 9, 6, 10, 0)
      )

      expect(metrics).to include(
        total_cards: 5,
        cards_this_month: 4,
        review_scheduled_count: 3,
        overdue_review_count: 1
      )
    end

    it "使用回数の多い自分のタグを5件まで返す" do
      cards = 3.times.map { |index| create(:card, user: user, title: "カード#{index}") }
      tags = {
        "Rails" => create(:tag, user: user, name: "Rails"),
        "Docker" => create(:tag, user: user, name: "Docker"),
        "Ruby" => create(:tag, user: user, name: "Ruby"),
        "CSS" => create(:tag, user: user, name: "CSS"),
        "JavaScript" => create(:tag, user: user, name: "JavaScript"),
        "SQL" => create(:tag, user: user, name: "SQL")
      }

      cards.each { |card| create(:tagging, card: card, tag: tags.fetch("Rails")) }
      cards.first(2).each { |card| create(:tagging, card: card, tag: tags.fetch("Docker")) }
      cards.last(2).each { |card| create(:tagging, card: card, tag: tags.fetch("Ruby")) }
      create(:tagging, card: cards[0], tag: tags.fetch("CSS"))
      create(:tagging, card: cards[1], tag: tags.fetch("JavaScript"))
      create(:tagging, card: cards[2], tag: tags.fetch("SQL"))

      secret_tag = create(:tag, user: other_user, name: "秘密タグ")
      6.times do
        other_card = create(:card, user: other_user)
        create(:tagging, card: other_card, tag: secret_tag)
      end

      expect(metrics[:top_tags].map { |tag| [ tag[:name], tag[:count] ] }).to eq(
        [
          [ "Rails", 3 ],
          [ "Docker", 2 ],
          [ "Ruby", 2 ],
          [ "CSS", 1 ],
          [ "JavaScript", 1 ]
        ]
      )
    end

    it "最近作成した自分のカードを新しい順に5件返す" do
      cards = 6.times.map do |index|
        create(
          :card,
          user: user,
          title: "最近のカード#{index}",
          created_at: Time.current - index.days
        )
      end
      create(:card, user: other_user, title: "他ユーザーの最新カード", created_at: Time.current)

      expect(metrics[:recent_cards]).to eq(cards.first(5))
    end

    it "理解できていない自分のカードだけを新しい順に5件返す" do
      low_cards = 6.times.map do |index|
        create(
          :card,
          user: user,
          title: "理解度が低いカード#{index}",
          understanding_level: :not_understood,
          created_at: Time.current - index.days
        )
      end
      create(
        :card,
        user: user,
        understanding_level: :mostly_understood,
        created_at: Time.current
      )
      create(:card, user: user, understanding_level: nil, created_at: Time.current)
      create(
        :card,
        user: other_user,
        understanding_level: :not_understood,
        created_at: Time.current
      )

      expect(metrics[:low_understanding_cards]).to eq(low_cards.first(5))
    end

    it "Tokyo時間を基準に直近6か月の作成数を0件の月も含めて返す" do
      2.times do
        create(
          :card,
          user: user,
          created_at: Time.zone.local(2026, 4, 1, 0, 0)
        )
      end
      create(
        :card,
        user: user,
        created_at: Time.zone.local(2026, 6, 15, 12, 0)
      )
      create(
        :card,
        user: user,
        created_at: Time.zone.local(2026, 9, 1, 0, 0)
      )
      create(
        :card,
        user: user,
        created_at: Time.zone.local(2026, 3, 31, 23, 59, 59)
      )
      create(
        :card,
        user: user,
        created_at: Time.zone.local(2026, 10, 1, 0, 0)
      )
      create(
        :card,
        user: other_user,
        created_at: Time.zone.local(2026, 9, 2, 0, 0)
      )

      expect(metrics[:monthly_card_counts]).to eq(
        [
          { month: Date.new(2026, 4, 1), count: 2 },
          { month: Date.new(2026, 5, 1), count: 0 },
          { month: Date.new(2026, 6, 1), count: 1 },
          { month: Date.new(2026, 7, 1), count: 0 },
          { month: Date.new(2026, 8, 1), count: 0 },
          { month: Date.new(2026, 9, 1), count: 1 }
        ]
      )
    end
  end
end
