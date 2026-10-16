require "rails_helper"

RSpec.describe "アカウント削除", type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:user) { create(:user) }

  it "確認画面で本人確認をしてアカウントを削除する" do
    create(:card, user: user)

    visit new_user_session_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン"

    click_link "アカウント削除"

    expect(page).to have_current_path(account_deletion_path)
    expect(page).to have_content("削除すると元に戻せません")

    fill_in "現在のパスワード", with: "password123"
    check "上記の内容を理解し、アカウント削除に同意します"

    expect do
      click_button "アカウントを削除する"
    end.to change(User, :count).by(-1)

    expect(page).to have_current_path(root_path)
    expect(page).to have_content(
      "アカウントを削除しました。ご利用ありがとうございました"
    )
    expect(Card.where(user_id: user.id)).to be_empty

    visit account_deletion_path
    expect(page).to have_current_path(new_user_session_path)
  end
end
