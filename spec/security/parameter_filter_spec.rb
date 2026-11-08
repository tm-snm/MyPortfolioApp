require "rails_helper"
require "stringio"

RSpec.describe "Private request logging" do
  it "filters nested content, search queries, credentials, and URLs without changing input" do
    marker = "private-content-fixture-128"
    input = {
      "card" => { "title" => marker, "body" => marker, "raw_content" => marker, "future_note" => marker },
      "prompt_template" => { "title" => marker, "description" => marker, "body" => marker, "category" => marker },
      "tag_names" => marker, "q" => marker,
      "user" => { "email" => marker, "password" => marker },
      "reset_password_token" => marker
    }
    request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/cards?q=#{marker}"))
    request.set_header("action_dispatch.parameter_filter", Rails.application.config.filter_parameters)
    filtered = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(input)
    expect(filtered.to_s).not_to include(marker)
    expect(request.filtered_path).not_to include(marker)
    expect(input.dig("card", "body")).to eq(marker)
  end

  it "does not expose posted content or search terms in real request log output" do
    output = StringIO.new
    logger = ActiveSupport::Logger.new(output)
    original = Rails.logger
    Rails.logger = logger
    user = create(:user)
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.post("/users/sign_in", params: { user: { email: user.email, password: "password123" } })
    marker = "private-request-fixture-128"
    session.post("/cards/preview_from_ai", params: { card: { raw_content: marker } })
    session.get("/cards", params: { q: marker })
    expect(output.string).to include("/cards", "[FILTERED]")
    expect(output.string).not_to include(marker)
  ensure
    Rails.logger = original
  end
end
