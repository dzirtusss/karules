# frozen_string_literal: true

require "fileutils"
# rubocop:disable Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity

require "json"

module KaRulesDSL # rubocop:disable Metrics/ModuleLength
  APPLE_KEYS = %w[spotlight].freeze
  private_constant :APPLE_KEYS

  def m(
    from, to = nil, conditions: nil, to_if_alone: nil, to_delayed_action: nil,
    to_if_held_down: nil, parameters: nil, to_after_key_up: nil
  )
    res = {}
    conditions = @default_conditions || conditions
    parameters = @default_parameters || parameters
    res[:conditions] = wrap(conditions) if conditions
    res[:parameters] = parameters if parameters

    res[:from] = from(from)

    res[:to] = to(to) if to
    res[:to_if_alone] = to(to_if_alone) if to_if_alone
    res[:to_if_held_down] = to(to_if_held_down) if to_if_held_down
    res[:to_delayed_action] = to_delayed_action if to_delayed_action
    res[:to_after_key_up] = to(to_after_key_up) if to_after_key_up

    res[:type] = "basic"
    @manipulators << res
  end

  def from(from)
    return from unless from.is_a?(String)

    args = from.split
    result =
      if args.first.match?(":")
        k, v = args.first.split(":")
        { k.to_sym => v }
      else
        { key_code: args.first }
      end
    args[1..].each do |mod|
      result[:modifiers] ||= {}
      if mod.start_with?("+")
        result[:modifiers][:mandatory] ||= []
        result[:modifiers][:mandatory] << mod[1..]
      elsif mod.start_with?("-")
        result[:modifiers][:optional] ||= []
        result[:modifiers][:optional] << mod[1..]
      else
        raise(ArgumentError, "Unknown modifier: #{mod}")
      end
    end
    result
  end

  def to(to)
    return to.map { |t| to(t) } if to.is_a?(Array)
    return to unless to.is_a?(String)
    return { shell_command: to[1..] } if to.start_with?("!")

    args = to.split
    result = { key_code: args.first }
    args[1..].each do |mod|
      if mod == "lazy"
        result[:lazy] = true
      elsif mod.start_with?("+")
        result[:modifiers] ||= []
        result[:modifiers] << mod[1..]
      # elsif mod.start_with?("!")
      #   result[:shell_command] = mod[1..] + args.split(mod).last
      #   break
      else
        raise(ArgumentError, "Unknown modifier: #{mod}")
      end
    end
    result
  end

  def v(name, value)
    { set_variable: { name:, value: } }
  end

  def v_if(name, value, &)
    block_given? ? conditions(v_if(name, value), &) : { name:, type: "variable_if", value: }
  end

  def v_unless(name, value, &)
    block_given? ? conditions(v_unless(name, value), &) : { name:, type: "variable_unless", value: }
  end

  def mode_on(name = @default_mode) = v(name, true)
  def mode_off(name = @default_mode)= v(name, false)
  def mode_if(name = @default_mode, &) = v_if(name, true, &)
  def mode_unless(name = @default_mode, &) = v_unless(name, true, &)

  def apps(**apps)
    @apps = apps
  end

  def app_if(name, &)
    if block_given?
      conditions(app_if(name), &)
    else
      app = @apps[name] || raise(ArgumentError, "Unknown app: #{name}")
      { bundle_identifiers: wrap(app), type: "frontmost_application_if" }
    end
  end

  def app_unless(name, &)
    if block_given?
      conditions(app_unless(name), &)
    else
      app = @apps[name] || raise(ArgumentError, "Unknown app: #{name}")
      { bundle_identifiers: wrap(app), type: "frontmost_application_unless" }
    end
  end

  def desc(description)
    @description = description
  end

  def wrap(obj_or_arr)
    obj_or_arr.is_a?(Array) ? obj_or_arr : [obj_or_arr]
  end

  def default_mode(name)
    @default_mode = name
  end

  def conditions(*conditions)
    original_conditions = @default_conditions
    @default_conditions = (@default_conditions || []) + conditions
    yield
    @default_conditions = original_conditions
  end

  def parameters(**parameters)
    original_parameters = @default_parameters
    @default_parameters = (@default_parameters || {}).merge(parameters)
    yield
    @default_parameters = original_parameters
  end

  def group(description = "", skip: false, enabled: true)
    return if skip

    @description = description
    @manipulators = []
    @default_mode = nil
    @default_conditions = nil
    @default_parameters = nil
    yield
    @result << { description: @description, manipulators: @manipulators }
    @result.last[:enabled] = false unless enabled
  end

  def karabiner_path(path = nil)
    return @karabiner_path if path.nil?

    @karabiner_path = File.expand_path(path)
  end

  def generate
    @result = []
    config
    @result = deep_sort(@result)
  end

  def call
    # Generate rules (this also loads the config which may set karabiner_path)
    rules = generate

    # Now we can determine the correct file path
    file = karabiner_path || default_karabiner_path

    # Backup existing file if requested (unless in dry-run mode)
    backup_file(file) if should_backup? && !dry_run?

    json = JSON.parse(File.read(file), symbolize_names: true)

    json[:profiles][0][:complex_modifications][:rules].replace(rules)

    return if dry_run? # Don't write in dry-run mode

    File.write(file, json.to_json)
    `karabiner_cli --format-json #{file}`
  end

  private

  def dry_run?
    ENV["KARULES_DRY_RUN"] == "1"
  end

  def should_backup?
    ENV["KARULES_BACKUP"] != "0"
  end

  def backup_file(file)
    return unless File.exist?(file)

    backup_path = "#{file}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}"
    FileUtils.cp(file, backup_path)
    puts("Backed up existing config to: #{backup_path}") if ENV["KARULES_VERBOSE"] == "1"
  end

  def default_karabiner_path
    config_home = ENV.fetch("XDG_CONFIG_HOME", File.expand_path("~/.config"))
    File.join(config_home, "karabiner", "karabiner.json")
  end

  def deep_sort(obj)
    case obj
    when Array
      obj.map { |el| deep_sort(el) }
    when Hash
      obj.sort_by { |k, _| k }
         .to_h.transform_values { |v| deep_sort(v) }
    else
      obj
    end
  end
end

# rubocop:enable Metrics/MethodLength,Metrics/AbcSize
# rubocop:enable Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
