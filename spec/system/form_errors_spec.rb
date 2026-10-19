require "rails_helper"

RSpec.describe "入力エラーからの修正", type: :system do
  before do
    driven_by(:rack_test)
    user = create(:user)
    visit new_user_session_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン"
  end

  it "カード保存の失敗後に本文とタグを保持し、修正して保存できる" do
    visit new_card_path
    fill_in "本文", with: "失いたくない本文"
    fill_in "タグ", with: "Rails, Docker"
    expect { click_button "カードを保存" }.not_to change(Card, :count)

    expect(page).to have_css("#card-errors", text: "タイトルを入力してください")
    expect(page).to have_field("本文", with: "失いたくない本文")
    expect(page).to have_field("タグ", with: "Rails, Docker")

    fill_in "タイトル", with: "修正したカード"
    expect { click_button "カードを保存" }.to change(Card, :count).by(1)
    expect(page).to have_content("カードを作成しました")
    expect(page).to have_content("失いたくない本文")
    expect(page).to have_content("Rails")
    expect(page).to have_content("Docker")
  end

  it "テンプレート保存の失敗後に本文を保持し、修正して保存できる" do
    visit new_prompt_template_path
    fill_in "カテゴリー", with: "学習"
    fill_in "プロンプト本文", with: "失いたくないプロンプト"
    expect { click_button "個人テンプレートを作成" }.not_to change(PromptTemplate, :count)

    expect(page).to have_css("#prompt-template-errors", text: "タイトルを入力してください")
    expect(page).to have_field("プロンプト本文", with: "失いたくないプロンプト")

    fill_in "タイトル", with: "修正したテンプレート"
    expect { click_button "個人テンプレートを作成" }.to change(PromptTemplate, :count).by(1)
    expect(page).to have_content("個人テンプレートを作成しました")
    expect(page).to have_content("失いたくないプロンプト")
  end
end
