module ApplicationHelper
  def field_error_attributes(record, attribute, error_id:)
    return {} unless error_id && record.errors[attribute].any?

    { aria: { invalid: true, describedby: error_id } }
  end

  def site_title
    "Recall Card | つまずきを、次の自分の知識に"
  end

  def site_description
    "Recall Cardは、AIや検索で解決した内容を、あとから見返せるカードとして整理・保存するサービスです。"
  end

  def public_site_url
    Rails.configuration.x.public_site_url.presence || request.base_url
  end

  def ogp_image_url
    image_url("ogp.png", host: public_site_url)
  end

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
