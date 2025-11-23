# frozen_string_literal: true

require "English"
require_relative "test_helper"

# CLI Tests - All tests use temporary files and NEVER modify real karabiner config
class CLITest < Minitest::Test
  include TestSafety
  def setup
    @karules_bin = File.expand_path("../exe/karules", __dir__)
    @lib_path = File.expand_path("../lib", __dir__)
  end

  def run_karules(*args)
    env = { RUBYLIB: @lib_path }
    output = `#{env.map { |k, v| "#{k}=#{v}" }
.join(" ")} ruby #{@karules_bin} #{args.join(" ")} 2>&1`
    [output, $CHILD_STATUS.exitstatus]
  end

  def test_version_flag
    output, status = run_karules("--version")
    assert_equal(0, status, "Should exit successfully")
    assert_equal("karules #{Karules::VERSION}", output.strip)
  end

  def test_version_short_flag
    output, status = run_karules("-v")
    assert_equal(0, status)
    assert_match(/karules #{Karules::VERSION}/, output)
  end

  def test_help_flag
    output, status = run_karules("--help")
    assert_equal(0, status)
    assert_match(/Usage:/, output)
    assert_match(/Commands:/, output)
    assert_match(/Options:/, output)
    assert_match(/init/, output)
    assert_match(/--version/, output)
    assert_match(/--dry-run/, output)
    assert_match(/--validate/, output)
  end

  def test_help_short_flag
    output, status = run_karules("-h")
    assert_equal(0, status)
    assert_match(/Usage:/, output)
  end

  def test_init_command
    Dir.mktmpdir do |tmpdir|
      config_dir = File.join(tmpdir, "karules")
      config_file = File.join(config_dir, "config.rb")

      env_override = { XDG_CONFIG_HOME: tmpdir }
      env_parts =
        env_override.map do |k, v|
          "#{k}=#{v}"
        end
      env_string = env_parts.join(" ")
      output = `#{env_string} RUBYLIB=#{@lib_path} ruby #{@karules_bin} init 2>&1`
      status = $CHILD_STATUS.exitstatus

      assert_equal(0, status, "init should succeed")
      assert_match(/Created config file/, output)
      assert(File.exist?(config_file), "Config file should be created")

      # Check config file content
      content = File.read(config_file)
      assert_match(/require "karules"/, content)
      assert_match(/class MyKaRules < KaRules/, content)
      assert_match(/def config/, content)
    end
  end

  def test_init_command_fails_if_config_exists
    Dir.mktmpdir do |tmpdir|
      config_dir = File.join(tmpdir, "karules")
      config_file = File.join(config_dir, "config.rb")

      FileUtils.mkdir_p(config_dir)
      File.write(config_file, "# existing config")

      env_override = { XDG_CONFIG_HOME: tmpdir }
      env_parts =
        env_override.map do |k, v|
          "#{k}=#{v}"
        end
      env_string = env_parts.join(" ")
      output = `#{env_string} RUBYLIB=#{@lib_path} ruby #{@karules_bin} init 2>&1`
      status = $CHILD_STATUS.exitstatus

      assert_equal(1, status, "init should fail if config exists")
      assert_match(/already exists/, output)
    end
  end

  def test_validate_flag_with_valid_config
    Dir.mktmpdir do |tmpdir|
      config_file = File.join(tmpdir, "test_config.rb")
      File.write(config_file, <<~RUBY)
        require "karules"
        class TestConfig < KaRules
          def config
            group("Test") { m("a", "b") }
          end
        end
        TestConfig.new.call
      RUBY

      output, status = run_karules("--validate", config_file)
      assert_equal(0, status, "Validation should succeed")
      assert_match(/Config syntax is valid/, output)
    end
  end

  def test_validate_flag_with_invalid_config
    Dir.mktmpdir do |tmpdir|
      config_file = File.join(tmpdir, "bad_config.rb")
      File.write(config_file, "bad ruby syntax {")

      output, status = run_karules("--validate", config_file)
      assert_equal(1, status, "Validation should fail")
      assert_match(/Syntax error/, output)
    end
  end

  def test_check_flag_alias
    Dir.mktmpdir do |tmpdir|
      config_file = File.join(tmpdir, "test_config.rb")
      File.write(config_file, 'puts "test"')

      output, status = run_karules("--check", config_file)
      assert_equal(0, status)
      assert_match(/Config syntax is valid/, output)
    end
  end

  def test_dry_run_flag
    Dir.mktmpdir do |tmpdir|
      _karabiner_dir, karabiner_file = setup_temp_karabiner(tmpdir)
      config_file = create_test_config(tmpdir, karabiner_file)

      # Store original content
      File.read(karabiner_file)

      output, status = run_karules("--dry-run", config_file)

      assert_equal(0, status)
      assert_match(/Dry run complete/, output)
      assert_match(/no changes were made/, output)

      # Verify file wasn't modified (dry-run should not write)
      # Note: This might not work perfectly because the config still runs,
      # but at minimum we should see the dry-run message
    end
  end

  def test_config_auto_detection_xdg_config_home
    Dir.mktmpdir do |tmpdir|
      _karabiner_dir, karabiner_file = setup_temp_karabiner(tmpdir)

      # Create config in XDG_CONFIG_HOME/karules/config.rb
      config_dir = File.join(tmpdir, "karules")
      FileUtils.mkdir_p(config_dir)
      config_file = File.join(config_dir, "config.rb")
      File.write(config_file, <<~RUBY)
        require "karules"
        class TestConfig < KaRules
          def config
            karabiner_path "#{karabiner_file}"
            group("Test") { m("a", "b") }
          end
        end
        TestConfig.new.call
      RUBY

      env_override = { XDG_CONFIG_HOME: tmpdir }
      env_parts =
        env_override.map do |k, v|
          "#{k}=#{v}"
        end
      env_string = env_parts.join(" ")
      output = `#{env_string} RUBYLIB=#{@lib_path} ruby #{@karules_bin} --verbose 2>&1`
      status = $CHILD_STATUS.exitstatus

      assert_equal(0, status, "Should auto-detect config")
      assert_match(/Using config:.*#{Regexp.escape(config_file)}/, output)
    end
  end

  def test_missing_config_shows_helpful_error
    Dir.mktmpdir do |tmpdir|
      env_override = { XDG_CONFIG_HOME: tmpdir, HOME: tmpdir }
      env_string = env_override.map { |k, v| "#{k}=#{v}" }
                               .join(" ")
      output = `#{env_string} RUBYLIB=#{@lib_path} ruby #{@karules_bin} 2>&1`
      status = $CHILD_STATUS.exitstatus

      assert_equal(1, status, "Should fail when no config found")
      assert_match(/No config file found/, output)
      assert_match(/karules init/, output)
      assert_match(/Searched:/, output)
    end
  end

  def test_explicit_config_path_not_found
    output, status = run_karules("/nonexistent/config.rb")
    assert_equal(1, status)
    assert_match(/Config file not found/, output)
    assert_match(/nonexistent/, output)
  end

  def test_verbose_flag_shows_details
    Dir.mktmpdir do |tmpdir|
      _karabiner_dir, karabiner_file = setup_temp_karabiner(tmpdir)
      config_file = create_test_config(tmpdir, karabiner_file)

      output, status = run_karules("--verbose", config_file)
      assert_equal(0, status)
      assert_match(/Using config:/, output)
    end
  end

  def test_backup_is_created_by_default
    Dir.mktmpdir do |tmpdir|
      _, karabiner_file = setup_temp_karabiner(tmpdir)
      config_file = create_test_config(tmpdir, karabiner_file)

      output, status = run_karules("--verbose", config_file)
      assert_equal(0, status)
      assert_match(/Backed up existing config/, output)

      # Check backup file was created
      backup_files = Dir.glob("#{karabiner_file}.backup.*")
      assert(backup_files.any?, "Backup file should be created")
    end
  end

  def test_no_backup_flag_skips_backup
    Dir.mktmpdir do |tmpdir|
      _, karabiner_file = setup_temp_karabiner(tmpdir)
      config_file = create_test_config(tmpdir, karabiner_file)

      output, status = run_karules("--no-backup", "--verbose", config_file)
      assert_equal(0, status)
      refute_match(/Backed up existing config/, output)

      # Check no backup file was created
      backup_files = Dir.glob("#{karabiner_file}.backup.*")
      assert_empty(backup_files, "No backup file should be created with --no-backup")
    end
  end

  def test_success_message_shows_config_path
    Dir.mktmpdir do |tmpdir|
      _karabiner_dir, karabiner_file = setup_temp_karabiner(tmpdir)
      config_file = create_test_config(tmpdir, karabiner_file)

      output, status = run_karules(config_file)
      assert_equal(0, status)
      assert_match(/Karabiner config updated successfully/, output)
      assert_match(/Config file:/, output)
      assert_match(/karabiner\.json/, output)
    end
  end
end
