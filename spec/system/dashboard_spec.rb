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

  it "復習リンクごとの範囲と、カード詳細への遷移を確認できる" do
    today = create(:card, :scheduled_for_review, user: user, title: "今日が復習日")
    future = create(:card, :scheduled_for_review, user: user, title: "今後が復習日", next_review_on: Date.current.tomorrow)
    unscheduled = create(:card, :scheduled_for_review, user: user, title: "復習日が未設定", next_review_on: nil)

    visit new_user_session_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン"
    click_link "ダッシュボード"

    expect(page).to have_current_path(dashboard_path)
    expect(page).to have_content("学習ダッシュボード")
    expect(find("#overdue-reviews-metric .dashboard-metric-value")).to have_text("1", exact: true)
    expect(find("#review-scheduled-metric .dashboard-metric-value")).to have_text("4", exact: true)

    within("main") { click_link "今日の復習を見る" }
    expect(page).to have_current_path(cards_path(review_filter: "due"))
    expect(page.all(".card-list-item h2").map(&:text)).to contain_exactly(card.title, today.title)

    visit dashboard_path
    click_link "期限超過のカードを見る"
    expect(page).to have_current_path(cards_path(review_filter: "overdue"))
    expect(page.all(".card-list-item h2").map(&:text)).to eq([ card.title ])

    visit dashboard_path
    click_link "復習予定のカードを見る"
    expect(page).to have_current_path(cards_path(review_filter: "all"))
    expect(page.all(".card-list-item h2").map(&:text)).to contain_exactly(
      card.title, today.title, future.title, unscheduled.title
    )

    visit dashboard_path
    click_link card.title
    expect(page).to have_current_path(card_path(card))
    expect(page).to have_content(card.title)
  end
end
