class CardParser
  TITLE_MARKER = "【タイトル】"
  BODY_MARKER = "【本文】"
  FUTURE_NOTE_MARKER = "【未来の自分へのメモ】"

  def initialize(raw_text)
    @raw_text = raw_text.to_s
  end

  def parse
    {
      title: extract_between(TITLE_MARKER, BODY_MARKER),
      body: extract_between(BODY_MARKER, FUTURE_NOTE_MARKER).presence || @raw_text.strip,
      future_note: extract_after(FUTURE_NOTE_MARKER),
      raw_content: @raw_text
    }
  end

  private

  def extract_between(start_marker, end_marker)
    pattern = /#{Regexp.escape(start_marker)}\s*(.*?)(?=#{Regexp.escape(end_marker)}|\z)/m
    @raw_text[pattern, 1]&.strip
  end

  def extract_after(marker)
    pattern = /#{Regexp.escape(marker)}\s*(.*)\z/m
    @raw_text[pattern, 1]&.strip
  end
end
