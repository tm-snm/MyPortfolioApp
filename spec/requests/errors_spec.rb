require "rails_helper"

RSpec.describe "Errors", type: :request do
  describe "存在しないページへアクセスする場合" do
    it "404を返す" do
      get "/aaaaa"

      expect(response).to have_http_status(:not_found)
    end
  end
end
