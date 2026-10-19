require "spec_helper"
require "tmpdir"
require "fileutils"
require "open3"
require "rbconfig"

RSpec.describe "Rails secret file exclusions" do
  let(:root) { File.expand_path("../..", __dir__) }
  let(:checker) { File.join(root, "bin/check_secret_files") }

  around do |example|
    Dir.mktmpdir("recall-card-secret-files-") do |directory|
      @directory = directory
      _output, status = Open3.capture2e("git", "init", "--quiet", directory)
      raise "Could not initialize test repository" unless status.success?

      FileUtils.cp(File.join(root, ".gitignore"), File.join(directory, ".gitignore"))
      example.run
    end
  end

  def check
    Open3.capture2e(RbConfig.ruby, checker, chdir: @directory)
  end

  it "accepts encrypted credentials without tracking decryption keys" do
    FileUtils.mkdir_p(File.join(@directory, "config"))
    File.write(File.join(@directory, "config/credentials.yml.enc"), "encrypted fixture")
    Open3.capture2e("git", "add", "config/credentials.yml.enc", chdir: @directory)

    output, status = check

    expect(status).to be_success
    expect(output).to include("untracked and ignored")
  end

  %w[config/master.key config/credentials/production.key].each do |path|
    it "rejects a force-added #{path} without exposing its contents" do
      absolute_path = File.join(@directory, path)
      FileUtils.mkdir_p(File.dirname(absolute_path))
      File.write(absolute_path, "private fixture content")
      Open3.capture2e("git", "add", "--force", path, chdir: @directory)

      output, status = check

      expect(status.exitstatus).to eq(1)
      expect(output).to include(path)
      expect(output).not_to include("private fixture content")
    end
  end

  it "rejects missing Git exclusion rules" do
    File.write(File.join(@directory, ".gitignore"), "")

    output, status = check

    expect(status.exitstatus).to eq(1)
    expect(output).to include("ignore rules must exclude")
  end
end
