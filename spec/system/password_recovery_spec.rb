require "rails_helper"

RSpec.describe "パスワード復旧", type: :system do
  before { driven_by(:rack_test) }

  it "ログイン画面から案内を要求し、メールのリンクから新しいパスワードを設定できる" do
    user = create(:user)
    visit new_user_session_path
    click_link "パスワードを忘れた方はこちら"
    fill_in "メールアドレス", with: user.email
    click_button "再設定メールを送信"
    expect(page).to have_current_path(new_user_session_path)

    token = ActionMailer::Base.deliveries.last.body.encoded[/reset_password_token=([^"&\s]+)/, 1]
    visit edit_user_password_path(reset_password_token: token)
    fill_in "新しいパスワード", with: "new-system-password-128", exact: true
    fill_in "新しいパスワード（確認）", with: "new-system-password-128"
    click_button "パスワードを変更"
    expect(page).to have_current_path(cards_path)
    expect(user.reload.valid_password?("new-system-password-128")).to be(true)
  end

  it "使えないリンクから再設定メールを要求し直せる" do
    driven_by(:rack_test)

    visit edit_user_password_path(reset_password_token: "invalid-fixture")
    fill_in "新しいパスワード", with: "unused-test-password", exact: true
    fill_in "新しいパスワード（確認）", with: "unused-test-password"
    click_button "パスワードを変更"

    expect(page).to have_content("このリンクでは再設定できません。")
    expect(page).to have_no_button("パスワードを変更")
    click_link "再設定メールをもう一度リクエストする"

    expect(page).to have_current_path(new_user_password_path)
    expect(page).to have_button("再設定メールを送信")
  end
end
