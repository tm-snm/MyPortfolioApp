require "rails_helper"

RSpec.describe "テンプレートのクイックアクセス", type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:user) { create(:user) }
  let!(:prompt_template) do
    create(
      :prompt_template,
      title: "お気に入りにする公式テンプレート",
      category: "system_spec"
    )
  end

  it "お気に入りから詳細へ移動し、お気に入りを解除できる" do
    visit new_user_session_path

    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン"
    click_link "プロンプト"

    template_card = find(".card", text: prompt_template.title)
    within(template_card) do
      click_button "お気に入り登録"
    end

    within("#favorite-templates") do
      expect(page).to have_link(
        prompt_template.title,
        href: prompt_template_path(prompt_template)
      )
      click_link prompt_template.title
    end

    expect(page).to have_current_path(prompt_template_path(prompt_template))
    click_button "お気に入り解除"

    expect(page).to have_current_path(prompt_template_path(prompt_template))
    expect(page).to have_button("お気に入り登録")

    visit prompt_templates_path

    within("#favorite-templates") do
      expect(page).to have_content("お気に入りはまだありません。")
    end
  end
end
