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
      expect(described_class.available_to(user)).to include(
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

  describe "利用設定との関連" do
    it "テンプレートを削除すると利用設定も削除する" do
      prompt_template = create(:prompt_template)
      preference = create(
        :prompt_template_preference,
        prompt_template: prompt_template
      )

      prompt_template.destroy

      expect(described_class.exists?(prompt_template.id)).to be(false)
      expect(PromptTemplatePreference.exists?(preference.id)).to be(false)
    end
  end

  describe "ユーザー別の利用状態" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let!(:favorite_template) { create(:prompt_template) }
    let!(:older_template) { create(:prompt_template) }
    let!(:newer_template) { create(:prompt_template) }
    let!(:other_users_template) do
      create(:prompt_template, :personal, user: other_user)
    end

    before do
      create(
        :prompt_template_preference,
        user: user,
        prompt_template: favorite_template,
        favorite: true
      )
      create(
        :prompt_template_preference,
        user: user,
        prompt_template: older_template,
        last_used_at: 2.days.ago
      )
      create(
        :prompt_template_preference,
        user: user,
        prompt_template: newer_template,
        last_used_at: 1.day.ago
      )
      create(
        :prompt_template_preference,
        user: user,
        prompt_template: other_users_template,
        favorite: true,
        last_used_at: Time.current
      )
    end

    it ".favorited_byは指定ユーザーのお気に入りを返す" do
      expect(described_class.favorited_by(user)).to include(favorite_template)
    end

    it ".recently_used_byは最近使用した順に返す" do
      expect(described_class.recently_used_by(user)).to eq(
        [ other_users_template, newer_template, older_template ]
      )
    end

    it ".available_toと組み合わせると他ユーザーの個人テンプレートを除外する" do
      available_favorites =
        described_class.available_to(user).favorited_by(user)
      available_recent =
        described_class.available_to(user).recently_used_by(user)

      expect(available_favorites).not_to include(other_users_template)
      expect(available_recent).not_to include(other_users_template)
    end
  end
end
