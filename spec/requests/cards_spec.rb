require "rails_helper"

RSpec.describe "Cards", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:card) { create(:card, user: user) }
  let(:other_card) { create(:card, user: other_user) }

  describe "GET /cards/new" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "新規作成画面を表示できる" do
        get new_card_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトされる" do
        get new_card_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /cards" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      context "有効なパラメータの場合" do
        let(:valid_params) do
          {
            card: {
              title: "DockerでGemを追加できなかった",
              body: "bundleの保存先に書き込み権限がなかった。",
              future_note: "Gem追加時はコンテナ内の権限を確認する。"
            }
          }
        end

        it "カードを作成できる" do
          expect do
            post cards_path, params: valid_params
          end.to change(Card, :count).by(1)
        end

        it "ログインユーザーにカードを紐づける" do
          post cards_path, params: valid_params

          created_card = Card.order(:created_at).last

          expect(created_card.user).to eq(user)
        end

        it "作成後にリダイレクトする" do
          post cards_path, params: valid_params

          expect(response).to redirect_to(root_path)
        end
      end

      context "無効なパラメータの場合" do
        let(:invalid_params) do
          {
            card: {
              title: "",
              body: "",
              future_note: ""
            }
          }
        end

        it "カードを作成しない" do
          expect do
            post cards_path, params: invalid_params
          end.not_to change(Card, :count)
        end

        it "422を返す" do
          post cards_path, params: invalid_params

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "バリデーションエラーを表示する" do
          post cards_path, params: invalid_params

          expect(response.body).to include("エラー")
        end
      end
    end

    context "ログインしていない場合" do
      let(:valid_params) do
        {
          card: {
            title: "テストカード",
            body: "テスト本文"
          }
        }
      end

      it "カードを作成しない" do
        expect do
          post cards_path, params: valid_params
        end.not_to change(Card, :count)
      end

      it "ログイン画面へリダイレクトされる" do
        post cards_path, params: valid_params

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /cards" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "正常に一覧画面を表示できる" do
        get cards_path

        expect(response).to have_http_status(:ok)
      end

      it "自分のカードを表示する" do
        card = create(:card, user: user, title: "自分のカード")

        get cards_path

        expect(response.body).to include(card.title)
      end

      it "他ユーザーのカードを表示しない" do
        create(:card, user: user, title: "自分のカード")
        create(:card, user: other_user, title: "他人のカード")

        get cards_path

        expect(response.body).to include("自分のカード")
        expect(response.body).not_to include("他人のカード")
      end

      it "カードを新しい順で表示する" do
        old_card = create(
          :card,
          user: user,
          title: "古いカード",
          created_at: 2.days.ago
        )

        new_card = create(
          :card,
          user: user,
          title: "新しいカード",
          created_at: 1.day.ago
        )

        get cards_path

        new_card_position = response.body.index(new_card.title)
        old_card_position = response.body.index(old_card.title)

        expect(new_card_position).to be < old_card_position
      end

      it "カードが0件でも正常に表示できる" do
        get cards_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("まだカードがありません")
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトされる" do
        get cards_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /cards/:id" do
    let(:card) do
      create(
        :card,
        user: user,
        title: "Railsのルーティング",
        body: "resourcesについて理解する",
        future_note: "routesを最初に確認する"
      )
    end

    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "自分のカード詳細を表示できる" do
        get card_path(card)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Railsのルーティング")
        expect(response.body).to include("resourcesについて理解する")
        expect(response.body).to include("routesを最初に確認する")
      end

      it "他ユーザーのカード詳細を表示できない" do
        get card_path(other_card)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトされる" do
        get card_path(card)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /cards/:id/edit" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "自分のカード編集画面を表示できる" do
        get edit_card_path(card)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(card.title)
      end

      it "他ユーザーのカード編集画面を表示できない" do
        get edit_card_path(other_card)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトされる" do
        get edit_card_path(card)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /cards/:id" do
    before do
      sign_in user
    end

    context "正常な値の場合" do
      it "カードを更新できる" do
        patch card_path(card), params: {
          card: {
            title: "更新後タイトル",
            body: "更新後本文",
            future_note: "更新後メモ"
          }
        }

        card.reload

        expect(card.title).to eq("更新後タイトル")
        expect(card.body).to eq("更新後本文")
        expect(card.future_note).to eq("更新後メモ")
        expect(response).to redirect_to(card_path(card))
      end
    end

    context "不正な値の場合" do
      it "カードを更新しない" do
        original_title = card.title
        original_body = card.body

        patch card_path(card), params: {
          card: {
            title: "",
            body: "変更された本文"
          }
        }

        card.reload

        expect(card.title).to eq(original_title)
        expect(card.body).to eq(original_body)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "他ユーザーのカードの場合" do
      it "カードを更新できない" do
        original_title = other_card.title

        patch card_path(other_card), params: {
          card: {
            title: "不正な更新"
          }
        }

        other_card.reload

        expect(other_card.title).to eq(original_title)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /cards/:id" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      context "自分のカードの場合" do
        it "カードを削除できる" do
          card

          expect do
            delete card_path(card)
          end.to change(Card, :count).by(-1)
        end

        it "削除後にカード一覧画面へリダイレクトされる" do
          delete card_path(card)

          expect(response).to redirect_to(cards_path)
        end
      end

      context "他ユーザーのカードの場合" do
        it "カードを削除できない" do
          other_card

          expect do
            delete card_path(other_card)
          end.not_to change(Card, :count)

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "ログインしていない場合" do
      it "カードを削除しない" do
        card

        expect do
          delete card_path(card)
        end.not_to change(Card, :count)
      end

      it "ログイン画面へリダイレクトされる" do
        delete card_path(card)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
