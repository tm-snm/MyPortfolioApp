require "rails_helper"

RSpec.describe "学習状態", type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:user) { create(:user) }

  around do |example|
    travel_to(Time.zone.local(2026, 9, 10, 12, 0)) { example.run }
  end

  let!(:card) do
    create(
      :card,
      :scheduled_for_review,
      user: user,
      title: "理解度と重要度を確認するカード",
      next_review_on: Date.current
    )
  end

  it "詳細で設定し、一覧で確認し、復習時に理解度を更新できる" do
    visit new_user_session_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン"

    visit card_path(card)

    within("section.card", text: "学習状態") do
      expect(page).to have_content("理解度：未設定")
      expect(page).to have_content("重要度：未設定")
      select "だいたい理解", from: "理解度"
      select "高", from: "重要度"
      click_button "学習状態を更新"
    end

    expect(page).to have_content("理解度・重要度を更新しました")
    expect(page).to have_content("理解度：だいたい理解")
    expect(page).to have_content("重要度：高")
    expect(card.reload).to have_attributes(
      understanding_level: "mostly_understood",
      importance: "high"
    )

    click_link "カード一覧へ戻る"

    within("article", text: card.title) do
      expect(page).to have_content("理解度：だいたい理解")
      expect(page).to have_content("重要度：高")
      click_link "詳細を見る"
    end

    next_review_on = Date.current + 1.week

    within("form[action='#{mark_reviewed_card_path(card)}']") do
      fill_in "復習後の次回復習日", with: next_review_on
      select "説明できる", from: "復習後の理解度"
      click_button "復習した"
    end

    expect(page).to have_content(
      "復習を記録し、次回復習日を設定しました"
    )
    expect(page).to have_content("理解度：説明できる")
    expect(page).to have_content("重要度：高")
    expect(card.reload).to have_attributes(
      next_review_on: next_review_on,
      last_reviewed_at: Time.current,
      understanding_level: "can_explain",
      importance: "high"
    )
  end
end
