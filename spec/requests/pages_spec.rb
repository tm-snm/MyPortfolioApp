require "rails_helper"

RSpec.describe "公開ページ", type: :request do
  describe "GET /terms" do
    it "未ログインでも利用規約を表示する" do
      get terms_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("利用規約")
      expect(response.body).to include("TM（以下「運営者」といいます。）")
    end
  end

  describe "GET /privacy" do
    it "未ログインでもプライバシーポリシーを表示する" do
      get privacy_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("プライバシーポリシー")
      expect(response.body).to include("Render")
      expect(response.body).to include("jsDelivr")
      expect(response.body).to include("Gmail")
    end
  end

  describe "GET /contact" do
    it "未ログインでも問い合わせ先を表示する" do
      get contact_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("お問い合わせ")
      expect(response.body).to include("tm.rc.port.app@gmail.com")
    end
  end

  describe "共通導線" do
    it "トップページのフッターから公開ページへ移動できる" do
      get root_path

      expect(response.body).to include(%(href="#{terms_path}"))
      expect(response.body).to include(%(href="#{privacy_path}"))
      expect(response.body).to include(%(href="#{contact_path}"))
    end

    it "新規登録画面から利用規約とプライバシーポリシーを確認できる" do
      get new_user_registration_path

      expect(response.body).to include(%(href="#{terms_path}"))
      expect(response.body).to include(%(href="#{privacy_path}"))
    end
  end
end
