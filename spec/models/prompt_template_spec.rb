require "rails_helper"

RSpec.describe PromptTemplate, type: :model do
  describe "バリデーション" do
    it "タイトル、カテゴリー、本文があれば有効である" do
      prompt_template = build(:prompt_template)

      expect(prompt_template).to be_valid
    end

    it "タイトルがない場合は無効である" do
      prompt_template = build(:prompt_template, title: nil)

      expect(prompt_template).to be_invalid
    end

    it "カテゴリーがない場合は無効である" do
      prompt_template = build(:prompt_template, category: nil)

      expect(prompt_template).to be_invalid
    end

    it "本文がない場合は無効である" do
      prompt_template = build(:prompt_template, body: nil)

      expect(prompt_template).to be_invalid
    end
  end

  describe "所有者" do
    it "ユーザーがいないテンプレートは公式として有効である" do
      prompt_template = build(:prompt_template, user: nil)

      expect(prompt_template).to be_valid
      expect(prompt_template).to be_official
    end

    it "ユーザーに紐づくテンプレートは個人テンプレートとして有効である" do
      prompt_template = build(:prompt_template, :personal)

      expect(prompt_template).to be_valid
      expect(prompt_template).not_to be_official
    end
  end

  describe ".available_to" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:official_template) { create(:prompt_template) }
    let!(:personal_template) do
      create(:prompt_template, :personal, user: user)
    end
    let!(:other_users_template) do
      create(:prompt_template, :personal, user: other_user)
    end

    it "公式テンプレートと指定ユーザーの個人テンプレートを返す" do
      expect(described_class.available_to(user)).to contain_exactly(
        official_template,
        personal_template
      )
    end

    it "他ユーザーの個人テンプレートを返さない" do
      expect(described_class.available_to(user)).not_to include(
        other_users_template
      )
    end
  end
end
