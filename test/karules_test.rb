# frozen_string_literal: true

require_relative "test_helper"

class KaRulesTest < Minitest::Test
  # Example config used for testing
  class TestConfig < KaRules
    def key_mode(key, mode)
      m(
        key,
        to_if_alone: { key_code: key, halt: true },
        to_after_key_up: mode_off(mode),
        to_delayed_action: { to_if_canceled: { key_code: key }, to_if_invoked: mode_on(mode) },
        parameters: {
          "basic.to_if_held_down_threshold_milliseconds": 300,
          "basic.to_delayed_action_delay_milliseconds": 300
        }
      )
    end

    def config
      apps(slack: "^com\\.tinyspeck\\.slackmacgap$", ghostty: "^com\\.mitchellh\\.ghostty$")

      group("Caps Lock") do
        m("caps_lock -any", "left_control")
      end

      group("Mouse buttons") do
        m("pointing_button:button5 -any", "f3")
      end

      group("Tmux") do
        app_unless(:ghostty) do
          m(
            "a +control",
            [
              "!/bin/sh ~/bin/myterm focus",
              { key_code: "vk_none", hold_down_milliseconds: 100 },
              "a +control"
            ]
          )
        end
      end

      group("Tab mode") do
        m("tab", "right_option lazy", to_if_alone: "tab")

        m("j +right_option", "down_arrow")
        m("k +right_option", "up_arrow")

        app_if(:slack) do
          m("h +right_option", "f6 +shift")
          m("l +right_option", "f6")
          m("semicolon +right_option", "right_arrow")
        end

        m("h +right_option", "left_arrow")
        m("l +right_option", "right_arrow")

        m("w +right_option", "right_arrow +right_option")
        m("b +right_option", "left_arrow +right_option")
        m("u +right_option", "page_up")
        m("d +right_option", "page_down")
      end

      group("Mouse mode", enabled: false) do
        default_mode("mouse-mode")
        scroll = "mouse-scroll"

        step = 1000
        mult1 = 0.5
        mult2 = 2
        wheel = 50

        key_mode("d", "mouse-mode")
        mode_if do
          m("left_shift +right_shift", mode_off)
          m("right_shift +left_shift", mode_off)
        end
        m("left_shift +right_shift", mode_on)
        m("right_shift +left_shift", mode_on)

        mode_if do
          mode_if(scroll) do
            m("j -any", { mouse_key: { vertical_wheel: wheel } })
            m("k -any", { mouse_key: { vertical_wheel: -wheel } })
            m("h -any", { mouse_key: { horizontal_wheel: wheel } })
            m("l -any", { mouse_key: { horizontal_wheel: -wheel } })
          end

          m("j -any", { mouse_key: { y: step } })
          m("k -any", { mouse_key: { y: -step } })
          m("h -any", { mouse_key: { x: -step } })
          m("l -any", { mouse_key: { x: step } })

          m("s -any", mode_on(scroll), to_after_key_up: mode_off(scroll))
          m("c -any", { mouse_key: { speed_multiplier: mult1 } })
          m("f -any", { mouse_key: { speed_multiplier: mult2 } })

          m("b -any", { pointing_button: "button1" })
          m("spacebar -any", { pointing_button: "button1" })
          m("n -any", { pointing_button: "button2" })

          m("u -any", { software_function: { set_mouse_cursor_position: { x: "20%", y: "20%" } } })
          m("i -any", { software_function: { set_mouse_cursor_position: { x: "80%", y: "20%" } } })
          m("o -any", { software_function: { set_mouse_cursor_position: { x: "20%", y: "80%" } } })
          m("p -any", { software_function: { set_mouse_cursor_position: { x: "80%", y: "80%" } } })
          m("m -any", { software_function: { set_mouse_cursor_position: { x: "50%", y: "50%" } } })
        end
      end

      group("MacOS double CmdQ") do
        default_mode("macos-q-command")
        m("q +command", "q +command", conditions: mode_if)
        m("q +command", mode_on, to_delayed_action: { to_if_canceled: mode_off, to_if_invoked: mode_off })
      end

      max = 9
      group("terminal 1-#{max}") do
        app_if(:ghostty) do
          (1..max).each { |i| m("#{i} +left_command", "!/bin/sh ~/bin/myterm focus #{i}") }
        end

        (1..max).each { |i| m("#{i} +left_option", "!/bin/sh ~/bin/myterm focus #{i}") }
      end

      group("Apps") do
        m("j +right_command", "!/bin/sh ~/bin/myterm focus")
        m("k +right_command", "!open -a 'Safari'")
        m("l +right_command", "!open -a 'BoltAI'")
        m("semicolon +right_command", "!open -a 'Claude'")

        m("u +right_command", "!open -a 'macai'")
        m("i +right_command", "!open -a 'Msty'")
        m("o +right_command", "!open -g hammerspoon://raycast-ai-chat")
        m("p +right_command", "!open -a 'Postico 2'")

        m("f +right_command", "!open -a 'Finder'")
        m("s +right_command", "!open -a 'Slack'")
        m("c +right_command", "!open -a 'Google Chrome'")
        m("t +right_command", "t +control +command +option")
        m("m +right_command", "!open -a 'Mail'")
        m("d +right_command", "!open -a 'Discord'")
        m("v +right_command", "!open -a 'Viber'")
        m("r +right_command", "!open -a 'Reminders'")
        m("f4", ["grave_accent_and_tilde +option", "!/bin/sh ~/bin/myghosttysize"])
        m("n +right_command", "!open -a 'Notes'")
      end
    end
  end

  def test_example_config_generates_expected_output
    run_config_and_compare(TestConfig)
  end

  private

  def run_config_and_compare(config_class)
    Dir.mktmpdir do |tmpdir|
      # Create minimal base karabiner structure
      tmp_karabiner = File.join(tmpdir, "karabiner.json")
      base_structure = { profiles: [{ complex_modifications: { rules: [] } }] }
      File.write(tmp_karabiner, JSON.generate(base_structure))

      # Create instance and configure it to use temp file
      config = config_class.new
      config.instance_eval do
        @karabiner_path = tmp_karabiner
      end

      # Run the config
      config.call

      # Read the generated output
      generated = JSON.parse(File.read(tmp_karabiner))

      # Read the expected fixture
      expected_fixture = File.expand_path("fixtures/karabiner.json", __dir__)
      expected = JSON.parse(File.read(expected_fixture))

      # Compare the rules section
      assert_equal(
        expected["profiles"][0]["complex_modifications"]["rules"],
        generated["profiles"][0]["complex_modifications"]["rules"],
        "Generated rules should match expected fixture"
      )
    end
  end
end
