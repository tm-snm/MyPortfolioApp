require "rails_helper"

RSpec.describe "学習ダッシュボード", type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:user) { create(:user) }
  let!(:card) do
    create(
      :card,
      :scheduled_for_review,
      user: user,
      title: "ダッシュボードで確認するカード",
      next_review_on: Date.current.yesterday,
      understanding_level: :mostly_understood
    )
  end

  it "ヘッダーから表示し、期限超過一覧とカード詳細へ移動できる" do
    visit new_user_session_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン"

    click_link "ダッシュボード"

    expect(page).to have_current_path(dashboard_path)
    expect(page).to have_content("学習ダッシュボード")
    expect(page).to have_content(card.title)

    within("#overdue-reviews-metric") do
      click_link "期限超過のカードを見る"
    end

    expect(page).to have_current_path(
      cards_path(review_filter: "overdue")
    )
    expect(page).to have_content(card.title)

    visit dashboard_path
    click_link card.title

    expect(page).to have_current_path(card_path(card))
    expect(page).to have_content(card.title)
  end
end
