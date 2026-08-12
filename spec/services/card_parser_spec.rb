require "rails_helper"

RSpec.describe CardParser do
  describe "#parse" do
    context "3つの見出しが揃っている場合" do
      let(:raw_text) do
        <<~TEXT
          【タイトル】
          DockerでGemを追加できなかった

          【本文】
          Gemのインストール時に権限エラーが発生した。
          Docker環境の書き込み権限を確認して解決した。

          【未来の自分へのメモ】
          Gem追加時はDocker環境の権限も確認する。
        TEXT
      end

      it "各項目を正しく抽出できる" do
        result = described_class.new(raw_text).parse

        expect(result[:title]).to eq("DockerでGemを追加できなかった")
        expect(result[:body]).to eq(
          "Gemのインストール時に権限エラーが発生した。\n" \
          "Docker環境の書き込み権限を確認して解決した。"
        )
        expect(result[:future_note]).to eq(
          "Gem追加時はDocker環境の権限も確認する。"
        )
        expect(result[:raw_content]).to eq(raw_text)
      end
    end

    context "タイトルの見出しがない場合" do
      let(:raw_text) do
        <<~TEXT
          【本文】
          本文だけ存在する。

          【未来の自分へのメモ】
          次回も本文を確認する。
        TEXT
      end

      it "titleはnilになり、他の項目は取得できる" do
        result = described_class.new(raw_text).parse

        expect(result[:title]).to be_nil
        expect(result[:body]).to eq("本文だけ存在する。")
        expect(result[:future_note]).to eq("次回も本文を確認する。")
      end
    end

    context "未来の自分へのメモがない場合" do
      let(:raw_text) do
        <<~TEXT
          【タイトル】
          テストタイトル

          【本文】
          テスト本文
        TEXT
      end

      it "future_noteはnilになり、タイトルと本文を取得できる" do
        result = described_class.new(raw_text).parse

        expect(result[:title]).to eq("テストタイトル")
        expect(result[:body]).to eq("テスト本文")
        expect(result[:future_note]).to be_nil
      end
    end

    context "本文の見出しがない場合" do
      let(:raw_text) do
        <<~TEXT
          固定形式ではないAIの回答です。
          この文章全体を本文として残します。
        TEXT
      end

      it "元の全文をbodyへフォールバックする" do
        result = described_class.new(raw_text).parse

        expect(result[:body]).to eq(raw_text.strip)
      end
    end

    context "固定形式とまったく異なる場合" do
      let(:raw_text) { "通常の文章だけが入力されています。" }

      it "titleとfuture_noteはnilになり、全文をbodyへ設定する" do
        result = described_class.new(raw_text).parse

        expect(result[:title]).to be_nil
        expect(result[:body]).to eq("通常の文章だけが入力されています。")
        expect(result[:future_note]).to be_nil
        expect(result[:raw_content]).to eq(raw_text)
      end
    end

    context "nilが入力された場合" do
      it "例外を発生させず空文字として処理する" do
        result = described_class.new(nil).parse

        expect(result[:title]).to be_nil
        expect(result[:body]).to eq("")
        expect(result[:future_note]).to be_nil
        expect(result[:raw_content]).to eq("")
      end
    end

    context "空文字が入力された場合" do
      it "例外を発生させず空文字として処理する" do
        result = described_class.new("").parse

        expect(result[:title]).to be_nil
        expect(result[:body]).to eq("")
        expect(result[:future_note]).to be_nil
        expect(result[:raw_content]).to eq("")
      end
    end
  end
end
