require "net/smtp"

module Users
  class PasswordsController < Devise::PasswordsController
    include AuthenticationRateLimiting

    rescue_from Net::SMTPError, IOError, SocketError, Timeout::Error,
                SystemCallError, OpenSSL::SSL::SSLError,
                with: :password_delivery_failed

    private

    def password_delivery_failed
      # Do not include the exception or its message: SMTP errors can contain PII.
      Rails.logger.error("Password reset delivery failed")
      render plain: "メール送信を完了できませんでした。時間をおいて再試行してください。",
             status: :service_unavailable
    end
  end
end
