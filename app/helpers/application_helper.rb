module ApplicationHelper
  def field_error_attributes(record, attribute, error_id:, description_id: nil)
    invalid = error_id && record.errors[attribute].any?
    descriptions = [ description_id, (error_id if invalid) ].compact
    return {} if descriptions.empty?

    { aria: { invalid: (true if invalid), describedby: descriptions.join(" ") } }
  end

  def account_form_submission_data(validation_error_id:, handle_server_errors: true)
    actions = %w[
      submit->form-submission#preventWhileSubmitting
      turbo:submit-start->form-submission#start
      turbo:submit-end->form-submission#end
      turbo:fetch-request-error->form-submission#requestFailed
    ]
    actions << "turbo:before-fetch-response->form-submission#preserveOnServerError" if handle_server_errors

    {
      controller: "form-submission",
      form_submission_validation_error_id_value: validation_error_id,
      action: actions.join(" ")
    }
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
