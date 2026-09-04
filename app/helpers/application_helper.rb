module ApplicationHelper
  MARKDOWN_ALLOWED_TAGS = %w[
    a blockquote br code del em h1 h2 h3 h4 h5 h6 hr li ol p pre
    strong table tbody td th thead tr ul
  ].freeze
  MARKDOWN_ALLOWED_ATTRIBUTES = %w[href lang title].freeze

  def render_markdown(text)
    markdown = text.to_s.encode(Encoding::UTF_8)
    html = Commonmarker.to_html(
      markdown,
      options: {
        extension: {
          autolink: true,
          header_ids: nil,
          table: true
        },
        render: {
          hardbreaks: true,
          unsafe: false
        }
      },
      plugins: {
        syntax_highlighter: nil
      }
    )

    sanitize(
      html,
      tags: MARKDOWN_ALLOWED_TAGS,
      attributes: MARKDOWN_ALLOWED_ATTRIBUTES
    )
  end
end
