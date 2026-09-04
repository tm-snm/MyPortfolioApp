require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#render_markdown" do
    it "Markdownを見出し、リスト、コード、表、リンクへ変換する" do
      markdown = <<~MARKDOWN
        # 見出し

        - 項目1
        - 項目2

        インライン`コード`

        ~~~ruby
        puts "hello"
        ~~~

        | 名前 | 値 |
        | --- | --- |
        | Rails | 7 |

        [公式サイト](https://rubyonrails.org/)
      MARKDOWN

      rendered = helper.render_markdown(markdown)

      expect(rendered).to include("<h1>見出し</h1>")
      expect(rendered).to include("<ul>", "<li>項目1</li>")
      expect(rendered).to include("<code>コード</code>")
      expect(rendered).to include("<pre", "<code>puts")
      expect(rendered).to include("<table>", "<th>名前</th>")
      expect(rendered).to include(
        '<a href="https://rubyonrails.org/">公式サイト</a>'
      )
    end

    it "危険なHTMLとURLを除去する" do
      markdown = <<~MARKDOWN
        <script>alert("xss")</script>
        <img src="x" onerror="alert('xss')">
        [危険なリンク](javascript:alert("xss"))
        <a href="https://example.com" onclick="alert('xss')">リンク</a>
      MARKDOWN

      rendered = helper.render_markdown(markdown)

      expect(rendered).not_to include(
        "<script",
        "<img",
        "onerror",
        "onclick",
        "javascript:"
      )
    end

    it "空値と通常テキストを安全に表示する" do
      expect(helper.render_markdown(nil)).to eq("")
      expect(helper.render_markdown("通常の本文")).to include(
        "<p>通常の本文</p>"
      )
    end
  end
end
