require "rails_helper"

RSpec.describe "復習スケジュール", type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:user) { create(:user) }
  let!(:card) do
    create(
      :card,
      user: user,
      title: "復習スケジュールを確認するカード"
    )
  end

  around do |example|
    travel_to(Time.zone.local(2026, 9, 9, 12, 0)) { example.run }
  end

  it "復習日を設定し、復習後の次回日を記録できる" do
    visit new_user_session_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン"

    visit card_path(card)

    fill_in "次回復習日", with: Date.current
    click_button "復習日を設定"

    expect(page).to have_content("次回復習日を設定しました")
    expect(page).to have_content("今日：2026/09/09")
    expect(card.reload).to be_review_later

    click_link "今日の復習"

    expect(page).to have_select("復習状況", selected: "今日まで")
    expect(page).to have_content(card.title)

    click_link "詳細を見る", href: card_path(card)

    next_review_on = Date.current + 1.week
    fill_in "復習後の次回復習日", with: next_review_on
    click_button "復習した"

    expect(page).to have_content(
      "復習を記録し、次回復習日を設定しました"
    )
    expect(page).to have_content("次回：2026/09/16")
    expect(page).to have_content("最終復習日時：2026/09/09 12:00")
    expect(card.reload).to have_attributes(
      status: "review_later",
      next_review_on: next_review_on,
      last_reviewed_at: Time.current
    )
  end
end
