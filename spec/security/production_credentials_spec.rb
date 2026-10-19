require "spec_helper"
require "active_support"
require "active_support/encrypted_file"
require "tmpdir"
require "open3"
require "rbconfig"
require "securerandom"
require "json"

RSpec.describe "Production credentials" do
  let(:root) { File.expand_path("../..", __dir__) }
  let(:probe) do
    <<~'RUBY'
      require "json"
      begin
        require File.join(Dir.pwd, "config/application")
        Rails.application.config.credentials.content_path = ENV.fetch("PROBE_CREDENTIALS_PATH")
        Rails.application.config.credentials.key_path = ENV.fetch("PROBE_ABSENT_KEY_PATH")
        require File.join(Dir.pwd, "config/environment")
        Rails.application.routes.draw do
          get "/credentials_probe", to: ->(env) {
            request = ActionDispatch::Request.new(env)
            if request.params["issue"]
              request.session[:credentials_probe] = true
            end
            [ 200, { "content-type" => "text/plain" }, [ request.session[:credentials_probe] ? "signed_in" : "anonymous" ] ]
          }
        end
        response = Rack::MockRequest.new(Rails.application).get(
          "https://example.com/credentials_probe#{ENV['PROBE_ISSUE'] == '1' ? '?issue=1' : ''}",
          "HTTP_COOKIE" => ENV.fetch("PROBE_COOKIE", "")
        )
        result = { status: response.status, body: response.body, cookie: response["set-cookie"] }
        puts JSON.generate(result)
      rescue StandardError => error
        warn "Production probe failed: #{error.class.name}"
        exit 1
      end
    RUBY
  end

  around do |example|
    Dir.mktmpdir("recall-card-production-credentials-") do |directory|
      @directory = directory
      @key = SecureRandom.hex(16)
      @credentials_path = File.join(directory, "credentials.yml.enc")
      key_path = File.join(directory, "fixture.key")
      File.write(key_path, @key, perm: 0o600)
      ActiveSupport::EncryptedFile.new(
        content_path: @credentials_path,
        key_path: key_path,
        env_key: "UNUSED_CREDENTIALS_SPEC_KEY",
        raise_if_missing_key: true
      ).write("secret_key_base: #{SecureRandom.hex(64)}\n")
      example.run
    end
  end

  def boot(key: @key, secret_key_base: nil, cookie: nil, issue: false)
    environment = {
      "RAILS_ENV" => "production",
      "RAILS_MASTER_KEY" => key,
      "SECRET_KEY_BASE" => secret_key_base,
      "SECRET_KEY_BASE_DUMMY" => nil,
      "DISABLE_BOOTSNAP" => "1",
      "RAILS_LOG_LEVEL" => "fatal",
      "PROBE_CREDENTIALS_PATH" => @credentials_path,
      "PROBE_ABSENT_KEY_PATH" => File.join(@directory, "absent.key"),
      "PROBE_COOKIE" => cookie,
      "PROBE_ISSUE" => issue ? "1" : "0"
    }
    output, status = Open3.capture2e(environment, RbConfig.ruby, "-e", probe, chdir: root)
    result = status.success? ? JSON.parse(output.lines.last) : nil
    [ result, status ]
  end

  it "boots production with a matching environment key" do
    result, status = boot

    expect(status.success?).to be(true)
    expect(result.fetch("status")).to eq(200)
  end

  it "refuses to boot without a decryption key" do
    _result, status = boot(key: nil)

    expect(status.success?).to be(false)
  end

  it "requires a decryption key even with SECRET_KEY_BASE set" do
    _result, status = boot(key: nil, secret_key_base: SecureRandom.hex(64))

    expect(status.success?).to be(false)
  end

  it "refuses to boot with a mismatched decryption key" do
    _result, status = boot(key: SecureRandom.hex(16))

    expect(status.success?).to be(false)
  end

  it "accepts current session cookies and rejects cookies after secret_key_base changes" do
    old_secret = SecureRandom.hex(64)
    issued, issue_status = boot(secret_key_base: old_secret, issue: true)
    expect(issue_status.success?).to be(true)
    cookie = Array(issued.fetch("cookie")).first.split(";", 2).first

    current, current_status = boot(secret_key_base: old_secret, cookie: cookie)
    expect(current_status.success?).to be(true)
    expect(current.fetch("body")).to eq("signed_in")

    rotated, rotated_status = boot(cookie: cookie)
    expect(rotated_status.success?).to be(true)
    expect(rotated.fetch("body")).to eq("anonymous")
  end
end
