require "rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "GET /" do
    context "when signed out" do
      it "shows sign-in and sign-up links" do
        get root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("ログイン")
        expect(response.body).to include("新規登録")
      end
    end

    context "when signed in" do
      let(:user) { create(:user) }

      it "shows the sign-out button" do
        sign_in user

        get root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("ログアウト")
        expect(response.body).to include(user.email)
      end
    end
  end

  describe "authentication pages" do
    it "shows the sign-up page" do
      get new_user_registration_path

      expect(response).to have_http_status(:ok)
    end

    it "shows the sign-in page" do
      get new_user_session_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /users/sign_in" do
    let!(:user) { create(:user) }

    it "正しい認証情報でログインし、成功メッセージを表示する" do
      post user_session_path,
           params: {
             user: {
               email: user.email,
               password: "password123"
             }
           }

      expect(response).to redirect_to(cards_path)

      follow_redirect!
      expect(response.body).to include("ログインしました")
      expect(response.body).not_to include("Translation missing")
    end

    it "誤ったパスワードではログインせず、共通のエラーを表示する" do
      post user_session_path,
           params: {
             user: {
               email: user.email,
               password: "wrong-password"
             }
           }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(
        "メールアドレスまたはパスワードが正しくありません"
      )
      expect(response.body).not_to include("Translation missing")
    end

    it "未登録のメールアドレスでも同じエラーを表示する" do
      post user_session_path,
           params: {
             user: {
               email: "unknown@example.com",
               password: "password123"
             }
           }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(
        "メールアドレスまたはパスワードが正しくありません"
      )
      expect(response.body).not_to include("Translation missing")
    end
  end

  describe "DELETE /users/sign_out" do
    it "ログアウトし、成功メッセージを表示する" do
      user = create(:user)
      sign_in user

      delete destroy_user_session_path

      expect(response).to redirect_to(root_path)

      follow_redirect!
      expect(response.body).to include("ログアウトしました")
      expect(response.body).not_to include("Translation missing")
    end
  end

  describe "認証が必要なページ" do
    it "未ログインの場合はログイン画面で認証要求を表示する" do
      get dashboard_path

      expect(response).to redirect_to(new_user_session_path)

      follow_redirect!
      expect(response.body).to include("ログインまたは新規登録が必要です")
      expect(response.body).not_to include("Translation missing")
    end
  end

  describe "POST /users" do
    it "有効な入力で登録し、成功メッセージを表示する" do
      expect do
        post user_registration_path,
             params: {
               user: {
                 email: "new-user@example.com",
                 password: "password123",
                 password_confirmation: "password123"
               }
             }
      end.to change(User, :count).by(1)

      expect(response).to redirect_to(cards_path)

      follow_redirect!
      expect(response.body).to include("アカウント登録が完了しました")
      expect(response.body).not_to include("Translation missing")
    end

    it "不正な入力では登録せず、日本語のエラーを表示する" do
      expect do
        post user_registration_path,
             params: {
               user: {
                 email: "",
                 password: "short",
                 password_confirmation: "different"
               }
             }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(
        "件のエラーがあるため、ユーザーを保存できませんでした"
      )
      expect(response.body).to include("メールアドレスを入力してください")
      expect(response.body).not_to include("Translation missing")
    end
  end
end
