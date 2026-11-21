require "rails_helper"

RSpec.describe "入力エラーからの修正", type: :system do
  let(:user) { create(:user) }

  before do
    driven_by(:rack_test)
    visit new_user_session_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン"
  end

  it "カード保存の失敗後に本文とタグを保持し、修正して保存できる" do
    visit new_card_path
    fill_in "本文", with: "失いたくない本文"
    fill_in "未来の自分へのメモ", with: "次回に使うメモ"
    fill_in "タグ", with: "Rails, Docker"
    expect { click_button "カードを保存" }.not_to(change { [ Card.count, Tag.count, Tagging.count ] })

    expect(page).to have_css("#card-errors", text: "タイトルを入力してください")
    expect(page).to have_field("本文", with: "失いたくない本文")
    expect(page).to have_field("未来の自分へのメモ", with: "次回に使うメモ")
    expect(page).to have_field("タグ", with: "Rails, Docker")

    fill_in "タイトル", with: "修正したカード"
    expect { click_button "カードを保存" }.to change(Card, :count).by(1)
    expect(page).to have_content("カードを作成しました")
    expect(page).to have_content("失いたくない本文")
    expect(page).to have_content("Rails")
    expect(page).to have_content("Docker")
  end

  it "カード更新の失敗後にメモを空にした意図とタグを保持し、修正して更新できる" do
    card = create(:card, user: user, title: "更新前のタイトル", future_note: "保存済みメモ")
    card.tags << create(:tag, user: user, name: "Rails")

    visit edit_card_path(card)
    fill_in "タイトル", with: "修正中のタイトル"
    fill_in "本文", with: ""
    fill_in "未来の自分へのメモ", with: ""
    fill_in "タグ", with: "Turbo"

    expect do
      click_button "カードを更新"
    end.not_to(change { [ card.reload.attributes, card.tags.pluck(:name), Tag.count ] })

    expect(page).to have_css("#card-errors", text: "本文を入力してください")
    expect(page).to have_field("タイトル", with: "修正中のタイトル")
    expect(page).to have_field("未来の自分へのメモ", with: "")
    expect(page).to have_field("タグ", with: "Turbo")

    fill_in "本文", with: "更新する本文"
    click_button "カードを更新"

    expect(page).to have_current_path(card_path(card))
    expect(page).to have_content("カードを更新しました")
    expect(card.reload.future_note).to eq("")
    expect(card.tags.pluck(:name)).to eq([ "Turbo" ])
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
