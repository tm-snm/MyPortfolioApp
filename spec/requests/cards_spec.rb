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

          created_card = Card.order(:created_at).last

          expect(response).to redirect_to(card_path(created_card))
        end
      end

      context "AI出力からカードを作成する場合" do
        let(:raw_content) do
          <<~TEXT
            【タイトル】
            DockerでGemを追加できなかった

            【本文】
            bundleの保存先に書き込み権限がなかった。

            【未来の自分へのメモ】
            Gem追加時はコンテナ内の権限を確認する。
          TEXT
        end

        let(:ai_card_params) do
          {
            card: {
              title: "DockerでGemを追加できなかった",
              body: "bundleの保存先に書き込み権限がなかった。",
              future_note: "Gem追加時はコンテナ内の権限を確認する。",
              raw_content: raw_content
            }
          }
        end

        it "AIの元出力をraw_contentとして保存できる" do
          post cards_path, params: ai_card_params

          created_card = Card.order(:created_at).last

          expect(created_card.raw_content).to eq(raw_content)
        end
      end

      context "タグを設定する場合" do
        let(:params_with_tags) do
          {
            card: {
              title: "Dockerのエラー",
              body: "Dockerの権限エラーを解決した"
            },
            tag_names: "Rails, Docker, GitHub"
          }
        end

        it "複数のタグを設定してカードを作成できる" do
          post cards_path, params: params_with_tags

          created_card = user.cards.order(:created_at).last

          expect(created_card.tags.pluck(:name)).to contain_exactly(
            "Rails",
            "Docker",
            "GitHub"
          )
        end

        it "タグ名の前後の空白と重複を除去する" do
          params_with_tags[:tag_names] = " Rails, Docker, Rails, , Docker "

          post cards_path, params: params_with_tags

          created_card = user.cards.order(:created_at).last

          expect(created_card.tags.pluck(:name)).to contain_exactly(
            "Rails",
            "Docker"
          )
        end

        it "既存のタグを再利用する" do
          existing_tag = create(:tag, user: user, name: "Rails")

          params_with_tags[:tag_names] = "Rails"

          expect do
            post cards_path, params: params_with_tags
          end.not_to change(Tag, :count)

          created_card = user.cards.order(:created_at).last

          expect(created_card.tags).to include(existing_tag)
        end

        it "他ユーザーの同名タグを利用しない" do
          other_tag = create(:tag, user: other_user, name: "Rails")

          params_with_tags[:tag_names] = "Rails"

          post cards_path, params: params_with_tags

          created_card = user.cards.order(:created_at).last

          expect(created_card.tags).not_to include(other_tag)
          expect(created_card.tags.first.user).to eq(user)
        end

        it "タグを設定しなくてもカードを作成できる" do
          expect do
            post cards_path, params: {
              card: {
                title: "タグなしカード",
                body: "本文"
              },
              tag_names: ""
            }
          end.to change(Card, :count).by(1)
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

      context "キーワード検索する場合" do
        let!(:title_match_card) do
          create(
            :card,
            user: user,
            title: "Dockerの権限エラー",
            body: "Gemのインストールに失敗した"
          )
        end

        let!(:body_match_card) do
          create(
            :card,
            user: user,
            title: "Railsのエラー",
            body: "Docker Composeを確認した"
          )
        end

        let!(:not_match_card) do
          create(
            :card,
            user: user,
            title: "Rubyの配列",
            body: "mapメソッドについて"
          )
        end

        it "タイトルの部分一致でカードを検索できる" do
          get cards_path, params: { q: "Docker" }

          expect(response.body).to include(title_match_card.title)
        end

        it "本文の部分一致でカードを検索できる" do
          get cards_path, params: { q: "Docker" }

          expect(response.body).to include(body_match_card.title)
        end

        it "一致しないカードを表示しない" do
          get cards_path, params: { q: "Docker" }

          expect(response.body).not_to include(not_match_card.title)
        end

        it "他ユーザーの一致するカードを表示しない" do
          other_match_card = create(
            :card,
            user: other_user,
            title: "Dockerのカード",
            body: "Dockerについて"
          )

          get cards_path, params: { q: "Docker" }

          expect(response.body).not_to include(other_match_card.title)
        end

        it "空の検索では通常の一覧を表示する" do
          get cards_path, params: { q: "" }

          expect(response.body).to include(title_match_card.title)
          expect(response.body).to include(not_match_card.title)
        end

        it "検索結果が0件の場合にメッセージを表示する" do
          get cards_path, params: { q: "存在しないキーワード" }

          expect(response.body).to include("一致するカードが見つかりませんでした")
        end
      end

      context "タグで絞り込む場合" do
        let(:rails_tag) { create(:tag, user: user, name: "Rails") }
        let(:docker_tag) { create(:tag, user: user, name: "Docker") }

        let(:rails_card) do
          create(:card, user: user, title: "Railsのエラー")
        end

        let(:docker_card) do
          create(:card, user: user, title: "Dockerのエラー")
        end

        let(:no_tag_card) do
          create(:card, user: user, title: "タグなしカード")
        end

        before do
          create(:tagging, card: rails_card, tag: rails_tag)
          create(:tagging, card: docker_card, tag: docker_tag)

          no_tag_card
        end

        it "選択したタグを持つカードだけ表示する" do
          get cards_path, params: { tag_id: rails_tag.id }

          expect(response.body).to include(rails_card.title)
          expect(response.body).not_to include(docker_card.title)
          expect(response.body).not_to include(no_tag_card.title)
        end
      end

      context "キーワード検索とタグ絞り込みを組み合わせる場合" do
        let(:rails_tag) { create(:tag, user: user, name: "Rails") }
        let(:docker_tag) { create(:tag, user: user, name: "Docker") }

        let(:matching_card) do
          create(
            :card,
            user: user,
            title: "Railsのルーティングエラー"
          )
        end

        let(:keyword_only_card) do
          create(
            :card,
            user: user,
            title: "RailsのDocker設定"
          )
        end

        let(:tag_only_card) do
          create(
            :card,
            user: user,
            title: "ActiveRecordの使い方"
          )
        end

        before do
          create(:tagging, card: matching_card, tag: rails_tag)
          create(:tagging, card: keyword_only_card, tag: docker_tag)
          create(:tagging, card: tag_only_card, tag: rails_tag)
        end

        it "キーワードとタグの両方に一致するカードだけ表示する" do
          get cards_path, params: {
            q: "Rails",
            tag_id: rails_tag.id
          }

          expect(response.body).to include(matching_card.title)
          expect(response.body).not_to include(keyword_only_card.title)
          expect(response.body).not_to include(tag_only_card.title)
        end
      end

      context "キーワード・タグ・復習予定を組み合わせる場合" do
        let(:rails_tag) do
          create(:tag, user: user, name: "Rails")
        end

        let(:docker_tag) do
          create(:tag, user: user, name: "Docker")
        end

        let!(:matching_card) do
          create(
            :card,
            user: user,
            title: "Railsのルーティングエラー",
            status: :review_later
          )
        end

        let!(:normal_card) do
          create(
            :card,
            user: user,
            title: "Railsの通常カード",
            status: :normal
          )
        end

        let!(:other_tag_card) do
          create(
            :card,
            user: user,
            title: "RailsのDockerカード",
            status: :review_later
          )
        end

        before do
          create(
            :tagging,
            card: matching_card,
            tag: rails_tag
          )

          create(
            :tagging,
            card: normal_card,
            tag: rails_tag
          )

          create(
            :tagging,
            card: other_tag_card,
            tag: docker_tag
          )
        end

        it "すべての条件に一致するカードだけ表示する" do
          get cards_path, params: {
            q: "Rails",
            tag_id: rails_tag.id,
            review: "1"
          }

          expect(response.body).to include(matching_card.title)
          expect(response.body).not_to include(normal_card.title)
          expect(response.body).not_to include(other_tag_card.title)
        end
      end

      context "他ユーザーのタグIDを指定した場合" do
        let(:other_tag) do
          create(:tag, user: other_user, name: "秘密タグ")
        end

        let(:other_card) do
          create(:card, user: other_user, title: "他ユーザーのカード")
        end

        before do
          create(:tagging, card: other_card, tag: other_tag)
        end

        it "他ユーザーのカードを表示しない" do
          get cards_path, params: { tag_id: other_tag.id }

          expect(response.body).not_to include(other_card.title)
        end
      end

      context "復習予定で絞り込む場合" do
        let!(:review_card) do
          create(
            :card,
            user: user,
            title: "復習するカード",
            status: :review_later
          )
        end

        let!(:normal_card) do
          create(
            :card,
            user: user,
            title: "通常カード",
            status: :normal
          )
        end

        let!(:other_review_card) do
          create(
            :card,
            user: other_user,
            title: "他人の復習カード",
            status: :review_later
          )
        end

        it "復習予定のカードだけ表示する" do
          get cards_path(review: "1")

          expect(response.body).to include(review_card.title)
          expect(response.body).not_to include(normal_card.title)
        end

        it "他ユーザーの復習予定カードを表示しない" do
          get cards_path, params: { review: "1" }

          expect(response.body).to include(review_card.title)
          expect(response.body).not_to include(other_review_card.title)
        end
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

      it "存在しないカードへアクセスする場合、404を返す" do
        get card_path(999999)

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
    context "ログインしている場合" do
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

      context "タグを変更する場合" do
        let(:rails_tag) do
          create(:tag, user: user, name: "Rails")
        end

        let(:docker_tag) do
          create(:tag, user: user, name: "Docker")
        end

        before do
          card.tags << rails_tag
          card.tags << docker_tag
        end

        it "タグを追加できる" do
          patch card_path(card), params: {
            card: {
              title: card.title,
              body: card.body
            },
            tag_names: "Rails, Docker, GitHub"
          }

          expect(card.reload.tags.pluck(:name)).to contain_exactly(
            "Rails",
            "Docker",
            "GitHub"
          )
        end

        it "タグを削除できる" do
          patch card_path(card), params: {
            card: {
              title: card.title,
              body: card.body
            },
            tag_names: "Rails"
          }

          expect(card.reload.tags.pluck(:name)).to contain_exactly("Rails")
        end

        it "タグをすべて外せる" do
          patch card_path(card), params: {
            card: {
              title: card.title,
              body: card.body
            },
            tag_names: ""
          }

          expect(card.reload.tags).to be_empty
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

      context "復習予定に変更する場合" do
        before do
          sign_in user
        end

        it "カードを復習予定に変更できる" do
          patch card_path(card), params: {
            card: {
              status: "review_later"
            }
          }

          expect(card.reload).to be_review_later
        end
      end

      context "復習予定を解除する場合" do
        let(:card) do
          create(
            :card,
            user: user,
            status: :review_later
          )
        end

        before do
          sign_in user
        end

        it "カードを通常状態に戻せる" do
          patch card_path(card), params: {
            card: {
              status: "normal"
            }
          }

          expect(card.reload).to be_normal
        end
      end
    end

    context "ログインしていない場合" do
      it "カードを更新できない" do
        original_title = card.title

        patch card_path(card), params: {
          card: {
            title: "不正な更新"
          }
        }

        expect(card.reload.title).to eq(original_title)
        expect(response).to redirect_to(new_user_session_path)
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

  describe "GET /cards/new_from_ai" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "AI出力貼り付け画面を表示できる" do
        get new_from_ai_cards_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトされる" do
        get new_from_ai_cards_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /cards/preview_from_ai" do
    let(:raw_content) do
      <<~TEXT
        【タイトル】
        RailsのStrong Parametersについて

        【本文】
        Strong Parametersは、
        Controllerで受け取るパラメータを制限する仕組み。

        【未来の自分へのメモ】
        user_idをpermitしないことを確認する。
      TEXT
    end

    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "AI出力を解析してプレビューを表示する" do
        post preview_from_ai_cards_path,
            params: { raw_content: raw_content }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("RailsのStrong Parametersについて")
        expect(response.body).to include("Controllerで受け取るパラメータを制限する仕組み")
        expect(response.body).to include("user_idをpermitしないことを確認する")
      end

      it "プレビュー時にはカードを保存しない" do
        expect do
          post preview_from_ai_cards_path,
              params: { raw_content: raw_content }
        end.not_to change(Card, :count)
      end

      it "形式が崩れていても500エラーにならない" do
        post preview_from_ai_cards_path,
            params: {
              raw_content: "形式とは違うAIの回答です"
            }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("形式とは違うAIの回答です")
      end

      it "AI出力が空の場合は貼り付け画面を再表示する" do
        post preview_from_ai_cards_path,
            params: { raw_content: "" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("AIの出力を貼り付けてください")
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトされる" do
        post preview_from_ai_cards_path,
            params: { raw_content: raw_content }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
