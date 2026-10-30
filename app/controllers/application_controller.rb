class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :prevent_private_response_caching

  protected

  def after_sign_in_path_for(_resource)
    cards_path
  end

  private

  def prevent_private_response_caching
    response.headers["Cache-Control"] = "no-store"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
  end
end
