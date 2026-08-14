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
      click_link "カードを作成"
    end

    expect(page).to have_content("AI出力からカードを作成")

    raw_content = <<~TEXT
      【タイトル】
      Dockerの権限エラー

      【本文】
      Dockerコンテナ内でGemを追加すると権限エラーが発生した。
      Dockerイメージを再ビルドして依存関係を反映した。

      【未来の自分へのメモ】
      Gemfileを変更した場合はDockerイメージの再ビルドを確認する。
    TEXT

    fill_in "AIの出力", with: raw_content
    click_button "プレビュー"

    expect(page).to have_content("カード内容の確認")
    expect(page).to have_field(
      "タイトル",
      with: "Dockerの権限エラー"
    )

    fill_in "タグ", with: "Docker, Rails"

    expect do
      click_button "カードを保存"
    end.to change(Card, :count).by(1)

    expect(page).to have_content("Dockerの権限エラー")
    expect(page).to have_content("カードを作成しました")

    click_link "カード一覧"

    fill_in "キーワード", with: "Docker"
    click_button "絞り込む"

    expect(page).to have_content("Dockerの権限エラー")
    expect(page).not_to have_content("Rubyの配列について")
  end
end
