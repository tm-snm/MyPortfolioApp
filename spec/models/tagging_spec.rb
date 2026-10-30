require "rails_helper"

RSpec.describe Tagging, type: :model do
  describe "バリデーション" do
    let(:user) { create(:user) }
    let(:card) { create(:card, user: user) }
    let(:tag) { create(:tag, user: user) }

    it "カードとタグがあれば有効である" do
      tagging = build(:tagging, card: card, tag: tag)

      expect(tagging).to be_valid
    end

    it "同じカードとタグの組み合わせを重複登録できない" do
      create(:tagging, card: card, tag: tag)

      duplicate_tagging =
        build(:tagging, card: card, tag: tag)

      expect(duplicate_tagging).not_to be_valid
    end

    it "他ユーザーのタグを関連付けて保存できない" do
      foreign_tag = create(:tag)
      tagging = build(:tagging, card: card, tag: foreign_tag)

      expect { tagging.save }.not_to change(Tagging, :count)
      expect(tagging.errors[:tag]).to be_present
    end
  end
end
