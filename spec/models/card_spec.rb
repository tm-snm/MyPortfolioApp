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
end
