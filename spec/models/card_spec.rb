require "rails_helper"

RSpec.describe Card, type: :model do
  describe "validations" do
    it "必須項目が揃っていれば有効である" do
      card = build(:card)

      expect(card).to be_valid
    end

    it "userがなければ無効である" do
      card = build(:card, user: nil)

      expect(card).to be_invalid
      expect(card.errors[:user]).to be_present
    end

    it "titleが空なら無効である" do
      card = build(:card, title: nil)

      expect(card).to be_invalid
      expect(card.errors[:title]).to be_present
    end

    it "bodyが空なら無効である" do
      card = build(:card, body: nil)

      expect(card).to be_invalid
      expect(card.errors[:body]).to be_present
    end

    it "future_noteとraw_contentは空でも有効である" do
      card = build(:card, future_note: nil, raw_content: nil)

      expect(card).to be_valid
    end
  end

  describe "associations" do
    it "Userに紐づくCardを取得できる" do
      user = create(:user)
      card = create(:card, user: user)

      expect(card.user).to eq(user)
      expect(user.cards).to include(card)
    end

    it "Userを削除すると、そのUserのCardも削除される" do
      user = create(:user)
      create(:card, user: user)

      expect do
        user.destroy!
      end.to change(described_class, :count).by(-1)
    end
  end

  describe "status enum" do
    it "初期状態がnormalである" do
      card = described_class.new

      expect(card.status).to eq("normal")
      expect(card).to be_normal
    end

    it "normalとreview_laterが定義されている" do
      expect(described_class.statuses).to eq(
        "normal" => 0,
        "review_later" => 1
      )
    end
  end

  describe "learning metadata enums" do
    it "理解度を3段階で定義する" do
      expect(described_class.understanding_levels).to eq(
        "not_understood" => 0,
        "mostly_understood" => 1,
        "can_explain" => 2
      )
    end

    it "重要度を3段階で定義する" do
      expect(described_class.importances).to eq(
        "low" => 0,
        "medium" => 1,
        "high" => 2
      )
    end

    it "理解度と重要度は未設定でも有効である" do
      card = build(:card, understanding_level: nil, importance: nil)

      expect(card).to be_valid
    end

    it "定義外の理解度と重要度は無効である" do
      card = build(
        :card,
        understanding_level: "invalid",
        importance: "invalid"
      )

      expect(card).to be_invalid
      expect(card.errors[:understanding_level]).to be_present
      expect(card.errors[:importance]).to be_present
    end
  end

  describe ".search_by_keyword" do
    let(:user) { create(:user) }

    let!(:title_match_card) do
      create(
        :card,
        user: user,
        title: "Dockerの権限エラー",
        body: "Gemを追加できなかった"
      )
    end

    let!(:body_match_card) do
      create(
        :card,
        user: user,
        title: "Railsの学習",
        body: "Docker Composeで起動する"
      )
    end

    let!(:not_match_card) do
      create(
        :card,
        user: user,
        title: "Rubyの配列",
        body: "mapメソッドについて"
      )
    end

    it "タイトルにキーワードを含むカードを検索できる" do
      result = described_class.search_by_keyword("Docker")

      expect(result).to include(title_match_card)
    end

    it "本文にキーワードを含むカードを検索できる" do
      result = described_class.search_by_keyword("Docker")

      expect(result).to include(body_match_card)
    end

    it "キーワードを含まないカードは検索結果に含まれない" do
      result = described_class.search_by_keyword("Docker")

      expect(result).not_to include(not_match_card)
    end

    it "大文字小文字を区別せず検索できる" do
      result = described_class.search_by_keyword("docker")

      expect(result).to include(title_match_card, body_match_card)
    end

    it "検索対象をタイトルに限定できる" do
      result = described_class.search_by_keyword("Docker", "title")

      expect(result).to include(title_match_card)
      expect(result).not_to include(body_match_card)
    end

    it "検索対象を本文に限定できる" do
      result = described_class.search_by_keyword("Docker", "body")

      expect(result).to include(body_match_card)
      expect(result).not_to include(title_match_card)
    end

    it "不明な検索対象ではタイトルと本文を検索する" do
      result = described_class.search_by_keyword("Docker", "unknown")

      expect(result).to include(title_match_card, body_match_card)
    end

    it "SQLのワイルドカードを通常の文字として検索する" do
      percent_card = create(:card, user: user, title: "進捗100%のカード")
      no_percent_card = create(:card, user: user, title: "進捗1000のカード")

      result = described_class.search_by_keyword("%", "title")

      expect(result).to include(percent_card)
      expect(result).not_to include(no_percent_card)
    end
  end

  describe ".matching_title" do
    let(:user) { create(:user) }

    it "タイトルだけを大文字小文字を区別せず部分一致検索する" do
      title_match_card = create(:card, user: user, title: "Rails Routing")
      body_only_match_card = create(
        :card,
        user: user,
        title: "別のカード",
        body: "rails routing"
      )

      result = described_class.matching_title("RAILS")

      expect(result).to include(title_match_card)
      expect(result).not_to include(body_only_match_card)
    end
  end

  describe ".sorted_by" do
    let(:user) { create(:user) }
    let!(:old_card) do
      create(:card, user: user, created_at: 2.days.ago)
    end
    let!(:new_card) do
      create(:card, user: user, created_at: 1.day.ago)
    end

    it "newestでは新しいカードから並べる" do
      expect(described_class.sorted_by("newest")).to eq([ new_card, old_card ])
    end

    it "oldestでは古いカードから並べる" do
      expect(described_class.sorted_by("oldest")).to eq([ old_card, new_card ])
    end

    it "不明な並び順では新しいカードから並べる" do
      expect(described_class.sorted_by("unknown")).to eq([ new_card, old_card ])
    end
  end

  describe ".tagged_with" do
    let(:user) { create(:user) }

    let(:rails_tag) do
      create(:tag, user: user, name: "Rails")
    end

    let(:docker_tag) do
      create(:tag, user: user, name: "Docker")
    end

    let(:rails_card) do
      create(:card, user: user, title: "Railsカード")
    end

    let(:docker_card) do
      create(:card, user: user, title: "Dockerカード")
    end

    before do
      create(:tagging, card: rails_card, tag: rails_tag)
      create(:tagging, card: docker_card, tag: docker_tag)
    end

    it "指定したタグを持つカードだけ取得できる" do
      result = described_class.tagged_with(rails_tag.id)

      expect(result).to include(rails_card)
      expect(result).not_to include(docker_card)
    end
  end

  describe "review schedule scopes" do
    let(:reference_date) { Date.new(2026, 9, 9) }
    let!(:overdue_card) do
      create(
        :card,
        :scheduled_for_review,
        next_review_on: reference_date.yesterday
      )
    end
    let!(:today_card) do
      create(
        :card,
        :scheduled_for_review,
        next_review_on: reference_date
      )
    end
    let!(:this_week_card) do
      create(
        :card,
        :scheduled_for_review,
        next_review_on: reference_date.end_of_week
      )
    end
    let!(:later_card) do
      create(
        :card,
        :scheduled_for_review,
        next_review_on: reference_date.end_of_week + 1.day
      )
    end
    let!(:unscheduled_card) do
      create(:card, status: :review_later, next_review_on: nil)
    end
    let!(:normal_card) do
      create(:card, status: :normal, next_review_on: reference_date)
    end

    it "今日までの復習予定カードを取得する" do
      result = described_class.review_due_by(reference_date)

      expect(result).to contain_exactly(overdue_card, today_card)
    end

    it "今日の復習予定カードを取得する" do
      result = described_class.review_due_on(reference_date)

      expect(result).to contain_exactly(today_card)
    end

    it "今日から今週末までの復習予定カードを取得する" do
      result = described_class.review_due_between(
        reference_date,
        reference_date.end_of_week
      )

      expect(result).to contain_exactly(today_card, this_week_card)
    end

    it "期限超過の復習予定カードを取得する" do
      result = described_class.review_overdue_before(reference_date)

      expect(result).to contain_exactly(overdue_card)
    end

    it "日付未設定と通常カードを期限による結果へ含めない" do
      result = described_class.review_due_by(reference_date.end_of_week)

      expect(result).not_to include(unscheduled_card, normal_card, later_card)
    end
  end

  describe "review scheduling" do
    let(:card) { create(:card) }

    it "次回復習日を設定して復習予定にする" do
      next_review_on = Date.current + 1.day

      expect(card.schedule_review(next_review_on: next_review_on)).to be(true)
      expect(card.reload).to have_attributes(
        status: "review_later",
        next_review_on: next_review_on
      )
    end

    it "次回復習日が空ならスケジュールを保存しない" do
      expect(card.schedule_review(next_review_on: "")).to be(false)
      expect(card.errors[:next_review_on]).to be_present
      expect(card).to have_attributes(
        status: "normal",
        next_review_on: nil
      )
      expect(card.reload).to be_normal
    end

    it "過去日は新しい次回復習日として保存しない" do
      expect(
        card.schedule_review(next_review_on: Date.current.yesterday)
      ).to be(false)
      expect(card.reload).to have_attributes(
        status: "normal",
        next_review_on: nil
      )
    end

    it "復習日時と次回復習日を同時に記録する" do
      reviewed_at = Time.zone.local(2026, 9, 9, 12, 30)
      next_review_on = Date.current + 1.week

      expect(
        card.mark_reviewed(
          next_review_on: next_review_on,
          reviewed_at: reviewed_at
        )
      ).to be(true)
      expect(card.reload).to have_attributes(
        status: "review_later",
        next_review_on: next_review_on,
        last_reviewed_at: reviewed_at
      )
    end

    it "復習日時・次回復習日・理解度を同時に記録する" do
      reviewed_at = Time.zone.local(2026, 9, 9, 12, 30)
      next_review_on = Date.current + 1.week
      card.update!(understanding_level: :not_understood, importance: :high)

      expect(
        card.mark_reviewed(
          next_review_on: next_review_on,
          reviewed_at: reviewed_at,
          understanding_level: :mostly_understood
        )
      ).to be(true)
      expect(card.reload).to have_attributes(
        status: "review_later",
        next_review_on: next_review_on,
        last_reviewed_at: reviewed_at,
        understanding_level: "mostly_understood",
        importance: "high"
      )
    end

    it "理解度が不正なら復習情報も理解度も保存しない" do
      card.update!(understanding_level: :not_understood)

      expect(
        card.mark_reviewed(
          next_review_on: Date.current + 1.week,
          understanding_level: "invalid"
        )
      ).to be(false)
      expect(card).to have_attributes(
        status: "normal",
        next_review_on: nil,
        last_reviewed_at: nil,
        understanding_level: "not_understood"
      )
      expect(card.reload).to have_attributes(
        status: "normal",
        next_review_on: nil,
        last_reviewed_at: nil,
        understanding_level: "not_understood"
      )
    end

    it "次回復習日が不正なら復習日時も保存しない" do
      expect(
        card.mark_reviewed(next_review_on: Date.current.yesterday)
      ).to be(false)
      expect(card).to have_attributes(
        status: "normal",
        next_review_on: nil,
        last_reviewed_at: nil
      )
      expect(card.reload.last_reviewed_at).to be_nil
    end

    it "復習予定を解除しても最終復習日時を保持する" do
      reviewed_at = Time.zone.local(2026, 9, 8, 10, 0)
      card.update!(
        status: :review_later,
        next_review_on: Date.current,
        last_reviewed_at: reviewed_at
      )

      expect(card.cancel_review).to be(true)
      expect(card.reload).to have_attributes(
        status: "normal",
        next_review_on: nil,
        last_reviewed_at: reviewed_at
      )
    end
  end

  describe "#review_timing" do
    let(:today) { Date.new(2026, 9, 9) }

    it "復習予定日と基準日から表示区分を返す" do
      expect(build(:card).review_timing(today: today)).to eq(:none)
      expect(
        build(:card, status: :review_later).review_timing(today: today)
      ).to eq(:unscheduled)
      expect(
        build(:card, :scheduled_for_review, next_review_on: today.yesterday)
          .review_timing(today: today)
      ).to eq(:overdue)
      expect(
        build(:card, :scheduled_for_review, next_review_on: today)
          .review_timing(today: today)
      ).to eq(:today)
      expect(
        build(:card, :scheduled_for_review, next_review_on: today.end_of_week)
          .review_timing(today: today)
      ).to eq(:this_week)
      expect(
        build(
          :card,
          :scheduled_for_review,
          next_review_on: today.end_of_week + 1.day
        ).review_timing(today: today)
      ).to eq(:later)
    end
  end
end
