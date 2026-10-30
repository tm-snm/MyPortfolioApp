require "spec_helper"
require "digest"
load File.expand_path("../../bin/check_runtime_credentials", __dir__)

RSpec.describe RuntimeCredentialsAudit do
  let(:credentials) { Struct.new(:key, :secret_key_base).new("new-key-fixture", "new-secret-fixture") }
  let(:config) { Struct.new(:require_master_key).new(true) }
  let(:application) { Struct.new(:credentials, :secret_key_base, :config).new(credentials, credentials.secret_key_base, config) }

  before do
    stub_const("RuntimeCredentialsAudit::EXPOSED_KEY_DIGEST", Digest::SHA256.hexdigest("old-key-fixture"))
    stub_const("RuntimeCredentialsAudit::EXPOSED_SECRET_DIGEST", Digest::SHA256.hexdigest("old-secret-fixture"))
  end

  def report(environment = {})
    described_class.report(application: application, environment: environment)
  end

  it "accepts new credentials and outputs only boolean results" do
    result = report

    expect(described_class.safe?(result)).to be(true)
    expect(result.values.all? { |value| [ true, false ].include?(value) }).to be(true)
  end

  it "detects an exposed decryption key" do
    credentials.key = "old-key-fixture"
    result = report

    expect(result[:decryption_key_matches_exposed]).to be(true)
    expect(described_class.safe?(result)).to be(false)
  end

  it "detects an exposed credential secret even when overridden" do
    credentials.secret_key_base = "old-secret-fixture"
    application.secret_key_base = "new-secret-fixture"
    result = report("SECRET_KEY_BASE" => "new-secret-fixture")

    expect(result[:credentials_secret_matches_exposed]).to be(true)
    expect(result[:effective_secret_matches_exposed]).to be(false)
    expect(described_class.safe?(result)).to be(false)
  end

  it "detects an exposed effective secret from an environment override" do
    application.secret_key_base = "old-secret-fixture"
    result = report("SECRET_KEY_BASE" => application.secret_key_base)

    expect(result[:credentials_secret_matches_exposed]).to be(false)
    expect(result[:effective_secret_matches_exposed]).to be(true)
    expect(described_class.safe?(result)).to be(false)
  end

  it "does not accept missing credentials" do
    credentials.secret_key_base = nil
    result = report

    expect(result[:credentials_readable]).to be(false)
    expect(described_class.safe?(result)).to be(false)
  end

  it "does not accept production without mandatory decryption keys" do
    config.require_master_key = false

    expect(described_class.safe?(report)).to be(false)
  end

  it "requires removing an explicit secret override even if it matches credentials" do
    result = report("SECRET_KEY_BASE" => application.secret_key_base)

    expect(result[:effective_secret_from_credentials]).to be(true)
    expect(result[:explicit_secret_override]).to be(true)
    expect(described_class.safe?(result)).to be(false)
  end
end
