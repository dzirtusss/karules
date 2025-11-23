# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "fileutils"
require "json"
require "karules"
require "minitest/autorun"
require "tmpdir"

# Test Safety Module
# Ensures tests NEVER modify the user's real karabiner configuration
module TestSafety
  # Get the real karabiner config path (to ensure we NEVER use it in tests)
  def real_karabiner_path
    config_home = ENV.fetch("XDG_CONFIG_HOME", File.expand_path("~/.config"))
    File.join(config_home, "karabiner", "karabiner.json")
  end

  # Assert that a path is NOT the real karabiner config
  def assert_not_real_karabiner_path(path)
    refute_equal(
      real_karabiner_path,
      File.expand_path(path),
      "SAFETY VIOLATION: Test attempted to use real karabiner config at #{real_karabiner_path}"
    )
  end

  # Create a minimal karabiner.json structure for testing
  def minimal_karabiner_json
    { profiles: [{ complex_modifications: { rules: [] } }] }
  end

  # Setup a temporary karabiner config structure for testing
  # Returns [karabiner_dir, karabiner_file] paths
  def setup_temp_karabiner(tmpdir)
    karabiner_dir = File.join(tmpdir, "karabiner")
    karabiner_file = File.join(karabiner_dir, "karabiner.json")

    # SAFETY: Ensure we're using temp files, NOT real karabiner config
    assert_not_real_karabiner_path(karabiner_file)

    FileUtils.mkdir_p(karabiner_dir)
    File.write(karabiner_file, JSON.generate(minimal_karabiner_json))

    [karabiner_dir, karabiner_file]
  end

  # Create a test config file that uses the given karabiner path
  # config_content should be Ruby code that goes inside the `def config` method
  def create_test_config(tmpdir, karabiner_file, config_content: 'group("Test") { m("a", "b") }')
    config_file = File.join(tmpdir, "test_config.rb")
    File.write(config_file, <<~RUBY)
      require "karules"
      class TestConfig < KaRules
        def config
          karabiner_path "#{karabiner_file}"
          #{config_content}
        end
      end
      TestConfig.new.call
    RUBY
    config_file
  end
end
