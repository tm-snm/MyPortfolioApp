module Users
  class RegistrationsController < Devise::RegistrationsController
    include AuthenticationRateLimiting

    def destroy
      unless params[:deletion_confirmation] == "1"
        flash.now[:alert] = I18n.t(
          "account_deletions.confirmation_required"
        )
        return render "account_deletions/show",
                      status: :unprocessable_content
      end

      unless resource.valid_password?(params[:current_password])
        flash.now[:alert] = I18n.t(
          "account_deletions.invalid_password"
        )
        return render "account_deletions/show",
                      status: :unprocessable_content
      end

      super
    end
  end
end
