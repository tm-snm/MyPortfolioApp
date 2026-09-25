class CardMarkdownExporter
  MAX_FILENAME_BASE_BYTES = 180
  INVALID_FILENAME_CHARACTERS = %r{[/\\:*?"<>|\x00-\x1f\x7f]}.freeze

  def initialize(card:)
    @card = card
  end

  def content
    [
      "# #{single_line(@card.title)}",
      "作成日時: #{@card.created_at.in_time_zone.strftime('%Y/%m/%d %H:%M')}",
      tags_section,
      "## 本文\n\n#{@card.body}",
      future_note_section
    ].join("\n\n") + "\n"
  end

  def filename
    "#{filename_base}-#{@card.id}.md"
  end

  private

  def tags_section
    tag_names = @card.tags.order(:name).pluck(:name)
    tag_list =
      if tag_names.any?
        tag_names.map { |name| "- #{single_line(name)}" }.join("\n")
      else
        "- （なし）"
      end

    "## タグ\n\n#{tag_list}"
  end

  def future_note_section
    note = @card.future_note.presence || "（未記入）"

    "## 未来の自分へのメモ\n\n#{note}"
  end

  def filename_base
    base = @card.title.to_s.encode(
      Encoding::UTF_8,
      invalid: :replace,
      undef: :replace,
      replace: ""
    )
    base = base.unicode_normalize(:nfc)
               .gsub(INVALID_FILENAME_CHARACTERS, "-")
               .gsub(/[[:space:]-]+/, "-")
               .gsub(/\A[.-]+|[.-]+\z/, "")

    base = "card" if base.blank?
    base = truncate_to_bytes(base, MAX_FILENAME_BASE_BYTES)
             .sub(/[.-]+\z/, "")

    base.presence || "card"
  end

  def truncate_to_bytes(value, max_bytes)
    result = +""

    value.each_char do |character|
      break if result.bytesize + character.bytesize > max_bytes

      result << character
    end

    result
  end

  def single_line(value)
    value.to_s.gsub(/\R+/, " ").strip
  end
end
