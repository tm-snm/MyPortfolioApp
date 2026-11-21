require "rails_helper"

RSpec.describe "アカウント削除", type: :request do
  describe "GET /account/deletion" do
    it "未ログインの場合はログイン画面へ遷移する" do
      get account_deletion_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "ログイン中の場合は確認画面を表示する" do
      user = create(:user)
      sign_in user

      get account_deletion_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("アカウント削除")
      expect(response.body).to include("現在のパスワード")
      document = response.parsed_body
      expect(document.at_css("main a[href='#{privacy_path(anchor: "retention-and-deletion")}']")).to be_present
      expect(document.css("main a[href='#{cards_path}']").last.text).to include("削除せず戻る")
    end
  end

  describe "DELETE /users" do
    let!(:user) { create(:user) }

    before do
      sign_in user
    end

    it "削除への同意がない場合は削除しない" do
      expect do
        delete user_registration_path,
               params: { current_password: "password123" }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(
        "アカウント削除への同意を確認してください"
      )
      document = response.parsed_body
      expect(document.at_css("#deletion_confirmation")["aria-describedby"]).to eq("account-deletion-errors")
      expect(document.at_css("#current_password")["aria-invalid"]).to be_nil
    end

    it "現在のパスワードが誤っている場合は削除しない" do
      expect do
        delete user_registration_path,
               params: {
                 deletion_confirmation: "1",
                 current_password: "wrong-password"
               }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("現在のパスワードが正しくありません")
    end

    it "同意と正しいパスワードがある場合は本人と所有データを削除する" do
      card = create(:card, user: user)
      tag = create(:tag, user: user)
      tagging = create(:tagging, card: card, tag: tag)
      personal_template = create(:prompt_template, :personal, user: user)
      shared_template = create(:prompt_template)
      preference = create(:prompt_template_preference, user: user, prompt_template: shared_template)
      other_user = create(:user)
      other_card = create(:card, user: other_user)

      expect do
        delete user_registration_path,
               params: {
                 deletion_confirmation: "1",
                 current_password: "password123"
               }
      end.to change(User, :count).by(-1)

      expect(response).to redirect_to(root_path)
      expect(User.exists?(user.id)).to be(false)
      expect(Card.exists?(card.id)).to be(false)
      expect(Tag.exists?(tag.id)).to be(false)
      expect(Tagging.exists?(tagging.id)).to be(false)
      expect(PromptTemplate.exists?(personal_template.id)).to be(false)
      expect(PromptTemplatePreference.exists?(preference.id)).to be(false)
      expect(PromptTemplate.exists?(shared_template.id)).to be(true)
      expect(User.exists?(other_user.id)).to be(true)
      expect(Card.exists?(other_card.id)).to be(true)

      follow_redirect!
      expect(response.body).to include(
        "アカウントを削除しました。ご利用ありがとうございました"
      )
    end
  end
end
