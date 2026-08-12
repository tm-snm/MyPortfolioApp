require 'rails_helper'

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
end
