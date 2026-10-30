require "spec_helper"
require "open3"
require "tmpdir"
require "rbconfig"

RSpec.describe "Secret scanner output" do
  let(:root) { File.expand_path("../..", __dir__) }

  def run_scanner(code)
    Dir.mktmpdir("scanner-spec-") do |directory|
      scanner = File.join(directory, "scanner")
      File.write(scanner, "#!/usr/bin/env ruby\n#{code}", perm: 0o700)
      return Open3.capture2e(
        { "GITLEAKS_BIN" => scanner }, RbConfig.ruby,
        File.join(root, "bin/check_security_secrets"), chdir: root
      )
    end
  end

  it "fails on a finding but prints only approved metadata" do
    output, status = run_scanner(<<~'RUBY')
      require "json"
      report = ARGV[ARGV.index("--report-path") + 1]
      File.write(report, JSON.generate([{
        "RuleID" => "fixture-rule", "File" => "fixture.txt", "StartLine" => 1,
        "Secret" => "private-scanner-fixture", "Match" => "private-scanner-fixture"
      }]))
      warn "private-scanner-fixture"
      exit 1
    RUBY
    expect(status.success?).to be(false)
    expect(output).to include("fixture-rule", "fixture.txt")
    expect(output).not_to include("private-scanner-fixture", "Secret", "Match")
  end

  it "fails closed on tool errors and suppresses raw diagnostics" do
    output, status = run_scanner('warn "private-error-fixture"; exit 2')
    expect(status.success?).to be(false)
    expect(output).to include("scanner failed")
    expect(output).not_to include("private-error-fixture")
  end

  it "suppresses malformed report contents instead of printing a parser exception" do
    output, status = run_scanner(<<~'RUBY')
      report = ARGV[ARGV.index("--report-path") + 1]
      File.write(report, "private-malformed-fixture")
    RUBY
    expect(status.success?).to be(false)
    expect(output).to include("invalid scanner report")
    expect(output).not_to include("private-malformed-fixture")
  end
end
