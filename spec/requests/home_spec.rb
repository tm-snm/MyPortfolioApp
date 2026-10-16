require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    let(:title) { "Recall Card | つまずきを、次の自分の知識に" }
    let(:description) do
      "Recall Cardは、AIや検索で解決した内容を、あとから見返せるカードとして整理・保存するサービスです。"
    end

    it "returns a successful response" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Recall Card")
    end

    it "未ログインでも初期HTMLにサービス共通の紹介情報を一度ずつ出力する" do
      get root_path

      head = response.parsed_body.at_css("head")
      expect(head.at_css("title").text).to eq(title)

      {
        'name="description"' => description,
        'property="og:title"' => title,
        'property="og:description"' => description,
        'property="og:type"' => "website",
        'property="og:url"' => "http://www.example.com/",
        'property="og:image:width"' => "1200",
        'property="og:image:height"' => "630",
        'name="twitter:card"' => "summary_large_image",
        'name="twitter:title"' => title,
        'name="twitter:description"' => description
      }.each do |attribute, content|
        tags = head.css("meta[#{attribute}]")
        expect(tags.size).to eq(1)
        expect(tags.first["content"]).to eq(content)
      end

      image_tags = head.css('meta[property="og:image"], meta[name="twitter:image"]')
      expect(image_tags.size).to eq(2)
      expect(image_tags.pluck("content").uniq.size).to eq(1)
      expect(image_tags.first["content"]).to match(%r{\Ahttp://www\.example\.com/assets/ogp(?:-[a-f0-9]+)?\.png\z})
    end

    it "公開URL設定からHTTPSの絶対URLを生成し、クエリを含めない" do
      allow(Rails.configuration.x).to receive(:public_site_url)
        .and_return("https://recall-card.onrender.com")

      get root_path, params: { q: "非公開の検索語", next: "/cards/123" }

      head = response.parsed_body.at_css("head")
      expect(head.at_css('meta[property="og:url"]')["content"])
        .to eq("https://recall-card.onrender.com/")
      image_url = head.at_css('meta[property="og:image"]')["content"]
      expect(image_url).to match(%r{\Ahttps://recall-card\.onrender\.com/assets/ogp(?:-[a-f0-9]+)?\.png\z})
      expect(head.at_css('meta[name="twitter:image"]')["content"]).to eq(image_url)
    end

    [ "Twitterbot/1.0", "facebookexternalhit/1.1", "Slackbot-LinkExpanding 1.0" ].each do |user_agent|
      it "#{user_agent}がログインなしでOGPを取得できる" do
        get root_path, headers: { "User-Agent" => user_agent }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.at_css('head meta[property="og:title"]')["content"])
          .to eq(title)
      end
    end
  end
end
