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
end
