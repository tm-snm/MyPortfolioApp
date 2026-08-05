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
end
