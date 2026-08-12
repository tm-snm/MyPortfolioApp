require "rails_helper"

RSpec.describe Tag, type: :model do
  describe "バリデーション" do
    let(:user) { create(:user) }

    it "ユーザーとタグ名があれば有効である" do
      tag = build(:tag, user: user, name: "Rails")

      expect(tag).to be_valid
    end

    it "タグ名が空の場合は無効である" do
      tag = build(:tag, user: user, name: nil)

      expect(tag).not_to be_valid
    end

    it "同じユーザーが同名タグを作成できない" do
      create(:tag, user: user, name: "Rails")
      duplicate_tag = build(:tag, user: user, name: "Rails")

      expect(duplicate_tag).not_to be_valid
    end

    it "別ユーザーなら同名タグを作成できる" do
      other_user = create(:user)

      create(:tag, user: user, name: "Rails")
      tag = build(:tag, user: other_user, name: "Rails")

      expect(tag).to be_valid
    end
  end

  describe "関連付け" do
    let(:user) { create(:user) }
    let(:card) { create(:card, user: user) }

    it "カードに複数のタグを関連付けられる" do
      rails_tag = create(:tag, user: user, name: "Rails")
      docker_tag = create(:tag, user: user, name: "Docker")

      card.tags << rails_tag
      card.tags << docker_tag

      expect(card.tags).to contain_exactly(
        rails_tag,
        docker_tag
      )
    end

    it "1つのタグを複数カードで共有できる" do
      tag = create(:tag, user: user, name: "Rails")

      card1 = create(:card, user: user)
      card2 = create(:card, user: user)

      card1.tags << tag
      card2.tags << tag

      expect(tag.cards).to contain_exactly(
        card1,
        card2
      )
    end

    it "カードを削除するとTaggingは削除されるがTagは残る" do
      user = create(:user)
      card = create(:card, user: user)
      tag = create(:tag, user: user)

      create(:tagging, card: card, tag: tag)

      expect {
        card.destroy
      }.to change(Tagging, :count).by(-1)
        .and change(Tag, :count).by(0)
    end
  end
end
