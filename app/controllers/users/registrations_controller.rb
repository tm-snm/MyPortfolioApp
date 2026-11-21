module Users
  class RegistrationsController < Devise::RegistrationsController
    include AuthenticationRateLimiting

    def destroy
      unless params[:deletion_confirmation] == "1"
        return render_deletion_error(:deletion_confirmation, "account_deletions.confirmation_required")
      end

      unless resource.valid_password?(params[:current_password])
        return render_deletion_error(:current_password, "account_deletions.invalid_password")
      end

      super
    end

    private

    def render_deletion_error(field, message_key)
      @deletion_error_field = field
      @deletion_error = I18n.t(message_key)
      render "account_deletions/show", status: :unprocessable_content
    end
  end
end
