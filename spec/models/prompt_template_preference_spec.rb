require "rails_helper"

RSpec.describe PromptTemplatePreference, type: :model do
  describe "バリデーション" do
    it "ユーザーとテンプレートがあれば有効である" do
      preference = build(:prompt_template_preference)

      expect(preference).to be_valid
    end

    it "ユーザーがない場合は無効である" do
      preference = build(:prompt_template_preference, user: nil)

      expect(preference).to be_invalid
    end

    it "テンプレートがない場合は無効である" do
      preference = build(:prompt_template_preference, prompt_template: nil)

      expect(preference).to be_invalid
    end

    it "同じユーザーとテンプレートの組み合わせを重複できない" do
      existing_preference = create(:prompt_template_preference)
      duplicate_preference = build(
        :prompt_template_preference,
        user: existing_preference.user,
        prompt_template: existing_preference.prompt_template
      )

      expect(duplicate_preference).to be_invalid
    end

    it "ユーザーが異なれば同じテンプレートを登録できる" do
      prompt_template = create(:prompt_template)
      create(:prompt_template_preference, prompt_template: prompt_template)
      another_preference = build(
        :prompt_template_preference,
        prompt_template: prompt_template
      )

      expect(another_preference).to be_valid
    end
  end

  describe "scope" do
    let(:user) { create(:user) }
    let!(:favorite_preference) do
      create(
        :prompt_template_preference,
        user: user,
        favorite: true
      )
    end
    let!(:older_preference) do
      create(
        :prompt_template_preference,
        user: user,
        last_used_at: 2.days.ago
      )
    end
    let!(:newer_preference) do
      create(
        :prompt_template_preference,
        user: user,
        last_used_at: 1.day.ago
      )
    end

    it ".favoritesはお気に入りだけを返す" do
      expect(described_class.favorites).to contain_exactly(favorite_preference)
    end

    it ".recently_usedは使用日時があるものを新しい順に返す" do
      expect(described_class.recently_used).to eq(
        [ newer_preference, older_preference ]
      )
    end
  end
end
