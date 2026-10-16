require "rails_helper"

RSpec.describe User, type: :model do
  describe "factory" do
    it "is valid with valid attributes" do
      user = build(:user)

      expect(user).to be_valid
    end
  end

  describe "email" do
    it "does not allow duplicate email addresses" do
      create(:user, email: "test@example.com")
      duplicate_user = build(:user, email: "test@example.com")

      expect(duplicate_user).to be_invalid
    end
  end

  describe "プロンプトテンプレートとの関連" do
    it "ユーザーを削除すると個人テンプレートも削除する" do
      user = create(:user)
      personal_template = create(:prompt_template, :personal, user: user)

      user.destroy

      expect(PromptTemplate.exists?(personal_template.id)).to be(false)
    end

    it "ユーザーを削除しても公式テンプレートは削除しない" do
      user = create(:user)
      official_template = create(:prompt_template)

      user.destroy

      expect(PromptTemplate.exists?(official_template.id)).to be(true)
    end
  end

  describe "テンプレート利用設定との関連" do
    it "ユーザーを削除すると利用設定も削除する" do
      user = create(:user)
      preference = create(:prompt_template_preference, user: user)

      user.destroy

      expect(PromptTemplatePreference.exists?(preference.id)).to be(false)
    end
  end

  describe "アカウント削除" do
    it "所有データを削除し、他ユーザーのデータと公式テンプレートを残す" do
      user = create(:user)
      card = create(:card, user: user)
      tag = create(:tag, user: user)
      tagging = create(:tagging, card: card, tag: tag)
      personal_template = create(:prompt_template, :personal, user: user)
      official_template = create(:prompt_template)
      personal_preference = create(
        :prompt_template_preference,
        user: user,
        prompt_template: personal_template
      )
      official_preference = create(
        :prompt_template_preference,
        user: user,
        prompt_template: official_template
      )

      other_user = create(:user)
      other_card = create(:card, user: other_user)
      other_tag = create(:tag, user: other_user)
      other_tagging = create(
        :tagging,
        card: other_card,
        tag: other_tag
      )

      user.destroy!

      expect(Card.exists?(card.id)).to be(false)
      expect(Tag.exists?(tag.id)).to be(false)
      expect(Tagging.exists?(tagging.id)).to be(false)
      expect(PromptTemplate.exists?(personal_template.id)).to be(false)
      expect(
        PromptTemplatePreference.exists?(personal_preference.id)
      ).to be(false)
      expect(
        PromptTemplatePreference.exists?(official_preference.id)
      ).to be(false)

      expect(User.exists?(other_user.id)).to be(true)
      expect(Card.exists?(other_card.id)).to be(true)
      expect(Tag.exists?(other_tag.id)).to be(true)
      expect(Tagging.exists?(other_tagging.id)).to be(true)
      expect(PromptTemplate.exists?(official_template.id)).to be(true)
    end
  end
end
