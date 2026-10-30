require "rails_helper"

RSpec.describe "Security boundaries", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:card) { create(:card, user: other_user) }
  let(:template) { create(:prompt_template, :personal, user: other_user) }

  def protected_requests
    [
      [ :get, cards_path ], [ :get, new_card_path ], [ :post, cards_path ],
      [ :get, autocomplete_cards_path(format: :json) ],
      [ :get, new_from_ai_cards_path ], [ :post, preview_from_ai_cards_path ],
      [ :get, card_path(card) ], [ :get, edit_card_path(card) ],
      [ :patch, card_path(card) ], [ :put, card_path(card) ], [ :delete, card_path(card) ],
      [ :get, export_markdown_card_path(card) ],
      [ :patch, schedule_review_card_path(card) ], [ :patch, mark_reviewed_card_path(card) ],
      [ :delete, cancel_review_card_path(card) ], [ :patch, learning_metadata_card_path(card) ],
      [ :get, dashboard_path ], [ :get, account_deletion_path ],
      [ :get, prompt_templates_path ], [ :get, new_prompt_template_path ],
      [ :post, prompt_templates_path ], [ :get, prompt_template_path(template) ],
      [ :get, edit_prompt_template_path(template) ],
      [ :patch, prompt_template_path(template) ], [ :put, prompt_template_path(template) ],
      [ :delete, prompt_template_path(template) ],
      [ :post, favorite_prompt_template_path(template) ],
      [ :delete, unfavorite_prompt_template_path(template) ],
      [ :post, record_usage_prompt_template_path(template) ],
      [ :get, edit_user_registration_path ],
      [ :patch, user_registration_path ], [ :put, user_registration_path ],
      [ :delete, user_registration_path ]
    ]
  end

  it "rejects every private entry point when signed out without changing stored data" do
    card
    template
    before_counts = [ User.count, Card.count, Tag.count, Tagging.count, PromptTemplate.count, PromptTemplatePreference.count ]

    protected_requests.each do |method, path|
      public_send(method, path)
      expect(response.status).to be_in([ 302, 401 ]), "#{method} #{path}"
    end

    expect([ User.count, Card.count, Tag.count, Tagging.count, PromptTemplate.count, PromptTemplatePreference.count ])
      .to eq(before_counts)
  end

  it "rejects other owners for every card member method without modifying their records" do
    sign_in user
    original = card.attributes

    [
      [ :get, card_path(card) ], [ :get, edit_card_path(card) ],
      [ :get, export_markdown_card_path(card) ],
      [ :patch, card_path(card) ], [ :put, card_path(card) ], [ :delete, card_path(card) ],
      [ :patch, schedule_review_card_path(card) ], [ :patch, mark_reviewed_card_path(card) ],
      [ :delete, cancel_review_card_path(card) ], [ :patch, learning_metadata_card_path(card) ]
    ].each do |method, path|
      sign_in user
      public_send(method, path, params: { card: { title: "forged", user_id: user.id } })
      expect(response).to have_http_status(:not_found)
      expect(card.reload.attributes).to eq(original)
    end
  end

  it "rejects all member methods on another user's personal template" do
    sign_in user
    original = template.attributes

    [
      [ :get, prompt_template_path(template) ], [ :get, edit_prompt_template_path(template) ],
      [ :patch, prompt_template_path(template) ], [ :put, prompt_template_path(template) ],
      [ :delete, prompt_template_path(template) ],
      [ :post, favorite_prompt_template_path(template) ],
      [ :delete, unfavorite_prompt_template_path(template) ],
      [ :post, record_usage_prompt_template_path(template) ]
    ].each do |method, path|
      sign_in user
      expect do
        public_send(method, path, params: { prompt_template: { title: "forged", user_id: user.id } })
      end.not_to change(PromptTemplatePreference, :count)
      expect(response).to have_http_status(:not_found)
      expect(template.reload.attributes).to eq(original)
    end
  end

  it "ignores owner and association IDs injected into card creation and updates" do
    sign_in user
    foreign_tag = create(:tag, user: other_user)
    post cards_path, params: {
      card: { title: "own", body: "body", user_id: other_user.id, tag_ids: [ foreign_tag.id ] }
    }
    own_card = user.cards.last
    expect(own_card).to be_present
    expect(own_card.tags).to be_empty

    patch card_path(own_card), params: {
      card: { title: "edited", user_id: other_user.id, tag_ids: [ foreign_tag.id ] }
    }
    expect(own_card.reload.user).to eq(user)
    expect(own_card.tags).to be_empty
  end

  it "restricts favorite redirects to the current host" do
    sign_in user
    official = create(:prompt_template)
    post favorite_prompt_template_path(official), headers: { "Referer" => "https://outside.example/" }
    expect(response).to redirect_to(prompt_templates_path)
    delete unfavorite_prompt_template_path(official), headers: { "Referer" => "https://outside.example/" }
    expect(response).to redirect_to(prompt_templates_path)
    post favorite_prompt_template_path(official), headers: { "Referer" => prompt_template_url(official) }
    expect(response).to redirect_to(prompt_template_path(official))
  end

  it "treats SQL syntax and LIKE wildcards as search values within the current user" do
    sign_in user
    own = create(:card, user: user, title: "literal %_' OR 1=1 --")
    other = create(:card, user: other_user, title: own.title)
    get autocomplete_cards_path, params: { q: "%_' OR 1=1 --" }, as: :json
    expect(response.parsed_body.fetch("titles")).to eq([ own.title ])
    get cards_path, params: { q: "' OR 1=1 --", sort: "created_at; DROP TABLE cards" }
    expect(response).to have_http_status(:ok)
    expect(Card.exists?(other.id)).to be(true)
  end

  it "sanitizes AI preview HTML and Turbo without saving any cards" do
    sign_in user
    payload = "【タイトル】\n<script>alert(1)</script>\n【本文】\n<img src=x onerror=alert(1)>\n[bad](javascript:alert(1))"
    [ "text/html", "text/vnd.turbo-stream.html" ].each do |format|
      expect do
        post preview_from_ai_cards_path,
             params: { card: { raw_content: payload } }, headers: { "Accept" => format }
      end.not_to change(Card, :count)
      html = Nokogiri::HTML.fragment(response.body)
      expect(html.css(".markdown-content script, img[onerror], a[href^='javascript:']")).to be_empty
      expect(response.headers["Cache-Control"]).to include("no-store")
    end
  end

  it "prevents caching of private HTML, JSON, Turbo and downloadable responses" do
    sign_in user
    own = create(:card, user: user)
    [ cards_path, card_path(own), dashboard_path, prompt_templates_path,
      autocomplete_cards_path(format: :json), export_markdown_card_path(own) ].each do |path|
      get path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("no-store")
    end
  end

  it "enforces CSP with matching importmap nonces and no unrestricted inline scripts" do
    get new_user_session_path
    policy = response.headers.fetch("Content-Security-Policy")
    expect(response.parsed_body.at_css("meta[name='turbo-cache-control']")["content"]).to eq("no-cache")
    nonce = response.parsed_body.at_css("meta[name='csp-nonce']")["content"]
    expect(policy).to include("script-src 'self'", "'nonce-#{nonce}'", "object-src 'none'", "frame-ancestors 'none'")
    expect(policy).not_to include("'unsafe-inline'", "'unsafe-eval'")
    expect(response.parsed_body.css("script[type='importmap'], script[type='module']").map { |node| node["nonce"] })
      .to all(eq(nonce))
    expect(response.headers).not_to have_key("Content-Security-Policy-Report-Only")
    get new_user_session_path
    expect(response.parsed_body.at_css("meta[name='csp-nonce']")["content"]).not_to eq(nonce)
  end

  context "with actual CSRF protection enabled" do
    around do |example|
      original = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = original
    end

    it "rejects missing and forged tokens, but accepts a valid form token" do
      sign_in user
      get new_card_path
      token = response.parsed_body.at_css("meta[name='csrf-token']")["content"]
      attributes = { title: "CSRF test", body: "body" }
      [ nil, "forged" ].each do |invalid|
        expect do
          post cards_path, params: { card: attributes }, headers: { "X-CSRF-Token" => invalid }
        end.not_to change(Card, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end
      expect do
        post cards_path, params: { card: attributes }, headers: { "X-CSRF-Token" => token }
      end.to change(user.cards, :count).by(1)
    end

    it "protects the clipboard usage fetch and destructive member requests" do
      sign_in user
      own = create(:card, user: user)
      official = create(:prompt_template)
      get prompt_template_path(official)
      token = response.parsed_body.at_css("meta[name='csrf-token']")["content"]
      expect { post record_usage_prompt_template_path(official) }
        .not_to change(PromptTemplatePreference, :count)
      expect(response).to have_http_status(:unprocessable_content)
      post record_usage_prompt_template_path(official), headers: { "X-CSRF-Token" => token }
      expect(response).to have_http_status(:no_content)
      expect { delete card_path(own) }.not_to change(Card, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
