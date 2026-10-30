module AuthenticationRateLimiting
  extend ActiveSupport::Concern

  included do
    rate_limit to: 10, within: 3.minutes, only: :create,
               store: Rails.configuration.x.authentication_rate_limit_store,
               with: :authentication_rate_limit_exceeded
  end

  private

  def authentication_rate_limit_exceeded
    response.headers["Retry-After"] = "180"
    render plain: "試行回数が多すぎます。3分ほど待ってから再試行してください。",
           status: :too_many_requests
  end
end
