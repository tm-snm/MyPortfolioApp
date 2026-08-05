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
end
