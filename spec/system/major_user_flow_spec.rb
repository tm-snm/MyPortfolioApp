require "rails_helper"

RSpec.describe "主要ユーザーフロー", type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:user) { create(:user) }

  let!(:prompt_template) do
    create(
      :prompt_template,
      title: "System Spec用テンプレート",
      category: "system_spec"
    )
  end

  let!(:other_card) do
    create(
      :card,
      user: user,
      title: "Rubyの配列について",
      body: "Rubyの配列操作について学習した"
    )
  end

  it "ログインしてAI出力からカードを作成し、検索できる" do
    visit new_user_session_path

    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン"

    expect(page).to have_current_path(cards_path)
    expect(page).to have_content("カード一覧")

    click_link "プロンプト"

    expect(page).to have_content("プロンプトテンプレート")
    expect(page).to have_content(prompt_template.title)

    click_link(
      "詳細を見る",
      href: prompt_template_path(prompt_template)
    )

    expect(page).to have_content(prompt_template.title)

    within("main") do
      click_link "AI回答を貼り付ける"
    end

    expect(page).to have_content("AI出力からカードを作成")

    raw_content = <<~TEXT
      【タイトル】
      Dockerの権限エラー

      【本文】
      ## 状況

      Dockerコンテナ内でGemを追加すると権限エラーが発生した。

      - Dockerイメージを再ビルドする
      - 依存関係を反映する

      【未来の自分へのメモ】
      Gemfileを変更した場合はDockerイメージの再ビルドを確認する。
    TEXT

    fill_in "AIの出力", with: raw_content
    click_button "内容を確認"

    expect(page).to have_content("カード内容を確認・編集する")
    expect(page).to have_field(
      "タイトル",
      with: "Dockerの権限エラー"
    )
    within(".markdown-content") do
      expect(page).to have_css("h2", text: "状況")
      expect(page).to have_css("li", text: "Dockerイメージを再ビルドする")
    end

    fill_in "タイトル", with: "編集後のDocker権限エラー"
    fill_in "未来の自分へのメモ", with: "次回は編集後の手順も確認する。"
    fill_in "タグ", with: "Docker, Rails"

    expect do
      click_button "カードを保存"
    end.to change(Card, :count).by(1)

    expect(page).to have_content("編集後のDocker権限エラー")
    expect(page).to have_content("次回は編集後の手順も確認する。")
    expect(page).to have_content("カードを作成しました")
    within(".markdown-content") do
      expect(page).to have_css("h2", text: "状況")
    end

    created_card = user.cards.order(:created_at).last
    expect(created_card.raw_content).to eq(raw_content.gsub("\n", "\r\n"))
    expect(created_card.title).to eq("編集後のDocker権限エラー")
    expect(created_card.body).to include("## 状況")
    expect(created_card.body).not_to include("<h2>")

    click_link "カード一覧"

    fill_in "キーワード", with: "Docker"
    click_button "絞り込む"

    expect(page).to have_content("編集後のDocker権限エラー")
    expect(page).not_to have_content("Rubyの配列について")
  end
end
