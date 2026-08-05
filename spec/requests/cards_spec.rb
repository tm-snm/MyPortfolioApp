require "rails_helper"

RSpec.describe "Cards", type: :request do
  let(:user) { create(:user) }

  describe "GET /cards/new" do
    context "when the user is signed in" do
      before do
        sign_in user
      end

      it "returns a successful response" do
        get new_card_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the user is not signed in" do
      it "redirects to the sign-in page" do
        get new_card_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /cards" do
    context "with valid parameters" do
      before do
        sign_in user
      end

      let(:valid_params) do
        {
          card: {
            title: "DockerでGemを追加できなかった",
            body: "bundleの保存先に書き込み権限がなかった。",
            future_note: "Gem追加時はコンテナ内の権限を確認する。"
          }
        }
      end

      it "creates a card" do
        expect do
          post cards_path, params: valid_params
        end.to change(Card, :count).by(1)
      end

      it "associates the card with the signed-in user" do
        post cards_path, params: valid_params

        created_card = Card.order(:created_at).last

        expect(created_card.user).to eq(user)
      end

      it "redirects after creating the card" do
        post cards_path, params: valid_params

        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid parameters" do
      before do
        sign_in user
      end

      let(:invalid_params) do
        {
          card: {
            title: "",
            body: "",
            future_note: ""
          }
        }
      end

      it "does not create a card" do
        expect do
          post cards_path, params: invalid_params
        end.not_to change(Card, :count)
      end

      it "returns an unprocessable entity response" do
        post cards_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "displays validation errors" do
        post cards_path, params: invalid_params

        expect(response.body).to include("エラー")
      end
    end

    context "when the user is not signed in" do
      let(:valid_params) do
        {
          card: {
            title: "テストカード",
            body: "テスト本文"
          }
        }
      end

      it "does not create a card" do
        expect do
          post cards_path, params: valid_params
        end.not_to change(Card, :count)
      end

      it "redirects to the sign-in page" do
        post cards_path, params: valid_params

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
