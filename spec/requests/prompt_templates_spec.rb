require "rails_helper"

RSpec.describe "PromptTemplates", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  let!(:official_template) do
    create(
      :prompt_template,
      title: "公式テンプレート",
      category: "official"
    )
  end

  let!(:personal_template) do
    create(
      :prompt_template,
      :personal,
      user: user,
      title: "自分の個人テンプレート",
      category: "personal"
    )
  end

  let!(:other_users_template) do
    create(
      :prompt_template,
      :personal,
      user: other_user,
      title: "他人の個人テンプレート",
      category: "private"
    )
  end

  let(:valid_params) do
    {
      prompt_template: {
        title: "エラー調査用テンプレート",
        category: "技術調査",
        description: "エラーの原因と解決方法を整理する",
        body: "この会話から原因と解決方法を整理してください。"
      }
    }
  end

  describe "GET /prompt_templates" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "公式テンプレートと自分の個人テンプレートを表示する" do
        get prompt_templates_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(official_template.title)
        expect(response.body).to include(personal_template.title)
      end

      it "他ユーザーの個人テンプレートを表示しない" do
        get prompt_templates_path

        expect(response.body).not_to include(other_users_template.title)
      end

      it "公式テンプレートと個人テンプレートを区別して表示する" do
        get prompt_templates_path

        document = response.parsed_body
        cards = document.css(".card")
        official_card = cards.find do |card|
          card.text.include?(official_template.title)
        end
        personal_card = cards.find do |card|
          card.text.include?(personal_template.title)
        end

        expect(official_card.text).to include("公式")
        expect(personal_card.text).to include("個人")
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトされる" do
        get prompt_templates_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /prompt_templates/:id" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "公式テンプレートを表示できる" do
        get prompt_template_path(official_template)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(official_template.title)
        expect(response.body).to include("プロンプトをコピー")
      end

      it "コピー成功後の使用記録先をStimulusへ渡す" do
        get prompt_template_path(official_template)

        clipboard_element = response.parsed_body.at_css(
          "[data-controller='clipboard']"
        )

        expect(
          clipboard_element["data-clipboard-usage-url-value"]
        ).to eq(record_usage_prompt_template_path(official_template))
      end

      it "自分の個人テンプレートを表示できる" do
        get prompt_template_path(personal_template)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(personal_template.title)
        expect(response.body).to include("編集")
        expect(response.body).to include("削除")
      end

      it "公式テンプレートには編集・削除導線を表示しない" do
        get prompt_template_path(official_template)

        document = response.parsed_body

        expect(
          document.at_css(
            "a[href='#{edit_prompt_template_path(official_template)}']"
          )
        ).to be_nil
        expect(
          document.at_css(
            "form[action='#{prompt_template_path(official_template)}']"
          )
        ).to be_nil
      end

      it "他ユーザーの個人テンプレートを表示できない" do
        get prompt_template_path(other_users_template)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトされる" do
        get prompt_template_path(official_template)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /prompt_templates/new" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "個人テンプレート作成画面を表示できる" do
        get new_prompt_template_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("個人テンプレートを作成")
        expect(response.body).to include('name="prompt_template[title]"')
        expect(response.body).to include('name="prompt_template[body]"')
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトされる" do
        get new_prompt_template_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /prompt_templates" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "ログインユーザーの個人テンプレートを作成する" do
        expect do
          post prompt_templates_path, params: valid_params
        end.to change { user.prompt_templates.count }.by(1)

        created_template = user.prompt_templates.order(:created_at).last

        expect(created_template).to have_attributes(
          title: "エラー調査用テンプレート",
          category: "技術調査",
          description: "エラーの原因と解決方法を整理する",
          body: "この会話から原因と解決方法を整理してください。"
        )
        expect(response).to redirect_to(
          prompt_template_path(created_template)
        )
      end

      it "送信されたuser_idで所有者を変更できない" do
        forged_params = valid_params.deep_dup
        forged_params[:prompt_template][:user_id] = other_user.id

        post prompt_templates_path, params: forged_params

        expect(user.prompt_templates.order(:created_at).last.user).to eq(user)
      end

      it "不正な入力では個人テンプレートを作成しない" do
        invalid_params = valid_params.deep_dup
        invalid_params[:prompt_template][:title] = ""

        expect do
          post prompt_templates_path, params: invalid_params
        end.not_to change(PromptTemplate, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("タイトルを入力してください")
      end
    end

    context "ログインしていない場合" do
      it "テンプレートを作成せずログイン画面へリダイレクトする" do
        expect do
          post prompt_templates_path, params: valid_params
        end.not_to change(PromptTemplate, :count)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /prompt_templates/:id/edit" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "自分の個人テンプレート編集画面を表示できる" do
        get edit_prompt_template_path(personal_template)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(personal_template.title)
      end

      it "他ユーザーの個人テンプレートを編集できない" do
        get edit_prompt_template_path(other_users_template)

        expect(response).to have_http_status(:not_found)
      end

      it "公式テンプレートを編集できない" do
        get edit_prompt_template_path(official_template)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "ログインしていない場合" do
      it "ログイン画面へリダイレクトされる" do
        get edit_prompt_template_path(personal_template)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /prompt_templates/:id" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "自分の個人テンプレートを更新する" do
        patch prompt_template_path(personal_template), params: valid_params

        expect(personal_template.reload).to have_attributes(
          title: "エラー調査用テンプレート",
          category: "技術調査",
          description: "エラーの原因と解決方法を整理する",
          body: "この会話から原因と解決方法を整理してください。"
        )
        expect(response).to redirect_to(
          prompt_template_path(personal_template)
        )
      end

      it "不正な入力では個人テンプレートを更新しない" do
        original_title = personal_template.title
        invalid_params = valid_params.deep_dup
        invalid_params[:prompt_template][:title] = ""

        patch prompt_template_path(personal_template), params: invalid_params

        expect(personal_template.reload.title).to eq(original_title)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("タイトルを入力してください")
      end

      it "他ユーザーの個人テンプレートを更新できない" do
        original_title = other_users_template.title

        patch prompt_template_path(other_users_template), params: valid_params

        expect(other_users_template.reload.title).to eq(original_title)
        expect(response).to have_http_status(:not_found)
      end

      it "公式テンプレートを更新できない" do
        original_title = official_template.title

        patch prompt_template_path(official_template), params: valid_params

        expect(official_template.reload.title).to eq(original_title)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "ログインしていない場合" do
      it "テンプレートを更新せずログイン画面へリダイレクトする" do
        original_title = personal_template.title

        patch prompt_template_path(personal_template), params: valid_params

        expect(personal_template.reload.title).to eq(original_title)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /prompt_templates/:id" do
    context "ログインしている場合" do
      before do
        sign_in user
      end

      it "自分の個人テンプレートを削除する" do
        personal_template

        expect do
          delete prompt_template_path(personal_template)
        end.to change(PromptTemplate, :count).by(-1)

        expect(response).to redirect_to(prompt_templates_path)
        expect(response).to have_http_status(:see_other)
      end

      it "他ユーザーの個人テンプレートを削除できない" do
        other_users_template

        expect do
          delete prompt_template_path(other_users_template)
        end.not_to change(PromptTemplate, :count)

        expect(response).to have_http_status(:not_found)
      end

      it "公式テンプレートを削除できない" do
        official_template

        expect do
          delete prompt_template_path(official_template)
        end.not_to change(PromptTemplate, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "ログインしていない場合" do
      it "テンプレートを削除せずログイン画面へリダイレクトする" do
        personal_template

        expect do
          delete prompt_template_path(personal_template)
        end.not_to change(PromptTemplate, :count)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "お気に入り・最近使ったテンプレート" do
    describe "GET /prompt_templates" do
      before do
        sign_in user
      end

      it "ログインユーザーのお気に入りをクイックアクセスへ表示する" do
        create(
          :prompt_template_preference,
          user: user,
          prompt_template: official_template,
          favorite: true
        )
        create(
          :prompt_template_preference,
          user: other_user,
          prompt_template: other_users_template,
          favorite: true
        )

        get prompt_templates_path

        favorite_section = response.parsed_body.at_css("#favorite-templates")

        expect(favorite_section.text).to include(official_template.title)
        expect(favorite_section.text).not_to include(other_users_template.title)
      end

      it "他ユーザーが同じ公式テンプレートをお気に入りにしても表示しない" do
        create(
          :prompt_template_preference,
          user: other_user,
          prompt_template: official_template,
          favorite: true
        )

        get prompt_templates_path

        favorite_section = response.parsed_body.at_css("#favorite-templates")

        expect(favorite_section.text).not_to include(official_template.title)
        expect(favorite_section.text).to include(
          "お気に入りはまだありません。"
        )
      end

      it "最近使ったテンプレートを新しい順に5件まで表示する" do
        recent_templates = 6.times.map do |index|
          prompt_template = create(
            :prompt_template,
            :personal,
            user: user,
            title: "最近使ったテンプレート#{index}"
          )
          create(
            :prompt_template_preference,
            user: user,
            prompt_template: prompt_template,
            last_used_at: index.minutes.ago
          )
          prompt_template
        end

        get prompt_templates_path

        recent_titles = response.parsed_body
                                .css("#recent-templates .list-group-item")
                                .map { |link| link.text.squish }

        expect(recent_titles.length).to eq(5)
        expect(recent_titles).to eq(
          recent_templates.first(5).map { |template| "#{template.title} 個人" }
        )
        expect(recent_titles).not_to include(
          "#{recent_templates.last.title} 個人"
        )
      end
    end

    describe "POST /prompt_templates/:id/favorite" do
      context "ログインしている場合" do
        before do
          sign_in user
        end

        it "公式テンプレートをログインユーザーのお気に入りに登録する" do
          expect do
            post favorite_prompt_template_path(official_template)
          end.to change { user.prompt_template_preferences.count }.by(1)

          preference = user.prompt_template_preferences.last

          expect(preference).to have_attributes(
            prompt_template: official_template,
            favorite: true
          )
          expect(response).to redirect_to(prompt_templates_path)
        end

        it "自分の個人テンプレートをお気に入りに登録できる" do
          post favorite_prompt_template_path(personal_template)

          expect(
            user.prompt_template_preferences.exists?(
              prompt_template: personal_template,
              favorite: true
            )
          ).to be(true)
        end

        it "同じテンプレートを再登録しても利用設定を重複させない" do
          create(
            :prompt_template_preference,
            user: user,
            prompt_template: official_template,
            favorite: true
          )

          expect do
            post favorite_prompt_template_path(official_template)
          end.not_to change(PromptTemplatePreference, :count)
        end

        it "他ユーザーの個人テンプレートを登録できない" do
          expect do
            post favorite_prompt_template_path(other_users_template)
          end.not_to change(PromptTemplatePreference, :count)

          expect(response).to have_http_status(:not_found)
        end
      end

      context "ログインしていない場合" do
        it "利用設定を作成せずログイン画面へリダイレクトする" do
          expect do
            post favorite_prompt_template_path(official_template)
          end.not_to change(PromptTemplatePreference, :count)

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    describe "DELETE /prompt_templates/:id/unfavorite" do
      context "ログインしている場合" do
        before do
          sign_in user
        end

        it "使用履歴がないお気に入りの利用設定を削除する" do
          create(
            :prompt_template_preference,
            user: user,
            prompt_template: official_template,
            favorite: true
          )

          expect do
            delete unfavorite_prompt_template_path(official_template)
          end.to change(PromptTemplatePreference, :count).by(-1)

          expect(response).to redirect_to(prompt_templates_path)
          expect(response).to have_http_status(:see_other)
        end

        it "使用履歴がある場合は履歴を残してお気に入りだけ解除する" do
          last_used_at = 1.day.ago
          preference = create(
            :prompt_template_preference,
            user: user,
            prompt_template: official_template,
            favorite: true,
            last_used_at: last_used_at
          )

          expect do
            delete unfavorite_prompt_template_path(official_template)
          end.not_to change(PromptTemplatePreference, :count)

          expect(preference.reload.favorite).to be(false)
          expect(preference.last_used_at).to be_within(1.second).of(last_used_at)
        end

        it "他ユーザーの個人テンプレートを解除できない" do
          preference = create(
            :prompt_template_preference,
            user: other_user,
            prompt_template: other_users_template,
            favorite: true
          )

          delete unfavorite_prompt_template_path(other_users_template)

          expect(response).to have_http_status(:not_found)
          expect(preference.reload.favorite).to be(true)
        end
      end

      context "ログインしていない場合" do
        it "利用設定を変更せずログイン画面へリダイレクトする" do
          preference = create(
            :prompt_template_preference,
            user: user,
            prompt_template: official_template,
            favorite: true
          )

          delete unfavorite_prompt_template_path(official_template)

          expect(preference.reload.favorite).to be(true)
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    describe "POST /prompt_templates/:id/record_usage" do
      context "ログインしている場合" do
        before do
          sign_in user
        end

        it "公式テンプレートの最終使用日時を記録する" do
          expect do
            post record_usage_prompt_template_path(official_template)
          end.to change { user.prompt_template_preferences.count }.by(1)

          preference = user.prompt_template_preferences.last

          expect(preference.prompt_template).to eq(official_template)
          expect(preference.last_used_at).to be_within(1.second).of(Time.current)
          expect(response).to have_http_status(:no_content)
        end

        it "再使用時は既存の利用設定を更新する" do
          preference = create(
            :prompt_template_preference,
            user: user,
            prompt_template: official_template,
            last_used_at: 1.day.ago
          )

          expect do
            post record_usage_prompt_template_path(official_template)
          end.not_to change(PromptTemplatePreference, :count)

          expect(preference.reload.last_used_at).to be_within(1.second).of(
            Time.current
          )
        end

        it "他ユーザーの個人テンプレートを記録できない" do
          expect do
            post record_usage_prompt_template_path(other_users_template)
          end.not_to change(PromptTemplatePreference, :count)

          expect(response).to have_http_status(:not_found)
        end

        it "詳細画面を表示しただけでは使用日時を記録しない" do
          expect do
            get prompt_template_path(official_template)
          end.not_to change(PromptTemplatePreference, :count)
        end
      end

      context "ログインしていない場合" do
        it "利用設定を作成せずログイン画面へリダイレクトする" do
          expect do
            post record_usage_prompt_template_path(official_template)
          end.not_to change(PromptTemplatePreference, :count)

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end
end
