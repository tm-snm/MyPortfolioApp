require "rails_helper"

RSpec.describe "Authentication security", type: :request do
  let!(:user) { create(:user) }

  it "limits login requests per IP and allows retry after the window" do
    attributes = { user: { email: user.email, password: "incorrect" } }
    10.times do
      post user_session_path, params: attributes
      expect(response).to have_http_status(:unprocessable_content)
    end
    post user_session_path, params: attributes
    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers["Retry-After"]).to eq("180")
    expect(response.headers["Cache-Control"]).to include("no-store")
    get cards_path
    expect(response).to redirect_to(new_user_session_path)

    travel 181.seconds do
      post user_session_path, params: { user: { email: user.email, password: "password123" } }
      expect(response).to redirect_to(cards_path)
    end
  end

  it "limits registration without creating users and separates client IPs" do
    11.times { post user_registration_path, params: { user: { email: "", password: "" } } }
    expect(response).to have_http_status(:too_many_requests)
    expect(User.count).to eq(1)
    post user_registration_path, params: { user: { email: "", password: "" } },
         env: { "REMOTE_ADDR" => "192.0.2.2" }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "limits reset email requests without sending an extra email" do
    10.times { post user_password_path, params: { user: { email: user.email } } }
    expect do
      post user_password_path, params: { user: { email: user.email } }
    end.not_to change(ActionMailer::Base.deliveries, :count)
    expect(response).to have_http_status(:too_many_requests)
  end

  it "returns the same reset response for known and unknown addresses" do
    post user_password_path, params: { user: { email: user.email } }
    known = [ response.status, response.location, flash[:notice] ]
    post user_password_path, params: { user: { email: "unknown@example.com" } }
    expect([ response.status, response.location, flash[:notice] ]).to eq(known)
    expect(flash[:notice]).to be_present
  end

  it "changes the password once with a valid emailed token and rejects reuse" do
    post user_password_path, params: { user: { email: user.email } }
    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to eq([ user.email ])
    token = mail.body.encoded[/reset_password_token=([^"&\s]+)/, 1]
    expect(token).to be_present

    get edit_user_password_path, params: { reset_password_token: token }
    expect(response).to have_http_status(:ok)
    put user_password_path, params: {
      user: { reset_password_token: token, password: "changed-password-128", password_confirmation: "changed-password-128" }
    }
    expect(response).to redirect_to(cards_path)
    expect(user.reload.valid_password?("changed-password-128")).to be(true)
    expect(user.reset_password_token).to be_nil
    delete destroy_user_session_path

    original = user.encrypted_password
    put user_password_path, params: {
      user: { reset_password_token: token, password: "reused-password-128", password_confirmation: "reused-password-128" }
    }
    expect(response).to have_http_status(:unprocessable_content)
    expect(user.reload.encrypted_password).to eq(original)
  end

  it "rejects invalid and expired reset tokens without changing the password" do
    token = user.send_reset_password_instructions
    original = user.reload.encrypted_password
    travel 7.hours do
      [ token, "not-a-valid-token" ].each do |invalid|
        patch user_password_path, params: {
          user: { reset_password_token: invalid, password: "changed-password-128", password_confirmation: "changed-password-128" }
        }
        expect(response).to have_http_status(:unprocessable_content)
        expect(user.reload.encrypted_password).to eq(original)
      end
    end
  end

  it "handles SMTP failure without logging the exception message" do
    allow(User).to receive(:send_reset_password_instructions)
      .and_raise(Net::SMTPAuthenticationError, "private-smtp-fixture")
    expect(Rails.logger).to receive(:error).with("Password reset delivery failed")
    post user_password_path, params: { user: { email: user.email } }
    expect(response).to have_http_status(:service_unavailable)
    expect(response.body).not_to include("private-smtp-fixture")
  end

  it "keeps the password recovery link visible" do
    get new_user_session_path
    expect(response.parsed_body.at_css("a[href='#{new_user_password_path}']")).to be_present
  end

  it "handles connection and TLS delivery failures without revealing diagnostics" do
    [ Errno::ECONNREFUSED, OpenSSL::SSL::SSLError ].each do |error_class|
      allow(User).to receive(:send_reset_password_instructions)
        .and_raise(error_class, "private-transport-fixture")
      post user_password_path, params: { user: { email: user.email } }
      expect(response).to have_http_status(:service_unavailable)
      expect(response.body).not_to include("private-transport-fixture")
    end
  end
end
