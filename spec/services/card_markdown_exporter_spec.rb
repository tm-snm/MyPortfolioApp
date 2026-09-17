require "rails_helper"

RSpec.describe CardMarkdownExporter do
  subject(:exporter) { described_class.new(card: card) }

  let(:user) { create(:user) }
  let(:body) do
    <<~MARKDOWN
      ## 原因

      - 設定不足

      ~~~ruby
      puts "hello"
      ~~~
    MARKDOWN
  end
  let(:card) do
    create(
      :card,
      user: user,
      title: "Railsのルーティング",
      body: body,
      future_note: "まずroutesを確認する。",
      created_at: Time.zone.local(2026, 9, 17, 12, 34)
    )
  end

  before do
    rails_tag = create(:tag, user: user, name: "Rails")
    docker_tag = create(:tag, user: user, name: "Docker")
    create(:tagging, card: card, tag: rails_tag)
    create(:tagging, card: card, tag: docker_tag)
  end

  describe "#content" do
    it "カード内容を一般的なMarkdown構造で出力する" do
      markdown = exporter.content

      expect(markdown).to start_with("# Railsのルーティング\n\n")
      expect(markdown).to include("作成日時: 2026/09/17 12:34")
      expect(markdown).to include("## タグ\n\n- Docker\n- Rails")
      expect(markdown).to include("## 本文\n\n#{body}")
      expect(markdown).to include(
        "## 未来の自分へのメモ\n\nまずroutesを確認する。"
      )
      expect(markdown).to end_with("\n")
    end

    it "本文のMarkdownと長文を末尾まで保持する" do
      long_body = "本文開始\n#{'あ' * 10_000}\n本文末尾"
      card.update!(body: long_body)

      expect(exporter.content).to include(long_body)
      expect(exporter.content).to include("本文開始", "本文末尾")
    end

    it "タグと未来の自分へのメモがない場合も項目を明示する" do
      card.taggings.destroy_all
      card.update!(future_note: nil)

      expect(exporter.content).to include("## タグ\n\n- （なし）")
      expect(exporter.content).to include(
        "## 未来の自分へのメモ\n\n（未記入）"
      )
      expect(exporter.content).not_to include("nil")
    end

    it "タグ名の改行をファイル構造へ混入させない" do
      card.tags.first.update_column(:name, "Ruby\nRails")

      expect(exporter.content).to include("- Ruby Rails")
    end
  end

  describe "#filename" do
    it "日本語を保持し、ファイル名に使えない文字を安全化する" do
      card.update!(
        title: "Rails/WSL: \"日本語\" <確認>? | Docker * 🚀"
      )

      expect(exporter.filename).to include("日本語", "確認", "🚀")
      expect(exporter.filename).to end_with("-#{card.id}.md")
      expect(exporter.filename).not_to match(%r{[/\\:*?"<>|\x00-\x1f\x7f]})
    end

    it "安全化すると空になるタイトルには代替名を使う" do
      card.update!(title: "/\\:*?\"<>|")

      expect(exporter.filename).to eq("card-#{card.id}.md")
    end

    it "長い日本語タイトルをUTF-8文字の途中で壊さず短縮する" do
      card.update!(title: "あ" * 200)

      filename = exporter.filename
      basename = filename.delete_suffix("-#{card.id}.md")

      expect(filename).to be_valid_encoding
      expect(basename.bytesize).to be <= 180
      expect(filename).to end_with("-#{card.id}.md")
    end

    it "改行や制御文字をファイル名へ含めない" do
      card.update!(title: "Rails\nDocker\t確認")

      expect(exporter.filename).to eq("Rails-Docker-確認-#{card.id}.md")
    end
  end
end
