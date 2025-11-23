# frozen_string_literal: true

# Example Karabiner configuration
# Copy this file to ~/.config/karules/config.rb and customize it

require "karules"

class MyKaRules < KaRules
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
    # Optional: specify custom Karabiner config path
    # Default: $XDG_CONFIG_HOME/karabiner/karabiner.json or ~/.config/karabiner/karabiner.json
    # karabiner_path "~/custom/path/karabiner.json"

    apps(slack: "^com\\.tinyspeck\\.slackmacgap$", ghostty: "^com\\.mitchellh\\.ghostty$")

    group("Caps Lock") do
      # m("caps_lock -any", "left_control", to_if_alone: "escape")
      m("caps_lock -any", "left_control")
    end

    group("Mouse buttons") do
      m("pointing_button:button5 -any", "f3") # mission control
      # m("pointing_button:button5 -any", "tab +right_command")
    end

    group("Tmux") do
      app_unless(:ghostty) do
        # Example: Focus terminal app, wait, then send Ctrl+A
        # Replace with your own terminal focus script
        m("a +control", ["!open -a 'Terminal'", { key_code: "vk_none", hold_down_milliseconds: 100 }, "a +control"])
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

      # m("fn -any", mode_on, to_if_alone: "fn", to_after_key_up: mode_off)

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

        # normal movement
        m("j -any", { mouse_key: { y: step } })
        m("k -any", { mouse_key: { y: -step } })
        m("h -any", { mouse_key: { x: -step } })
        m("l -any", { mouse_key: { x: step } })

        # mode modifiers
        m("s -any", mode_on(scroll), to_after_key_up: mode_off(scroll))
        m("c -any", { mouse_key: { speed_multiplier: mult1 } })
        m("f -any", { mouse_key: { speed_multiplier: mult2 } })

        # buttons
        m("b -any", { pointing_button: "button1" })
        m("spacebar -any", { pointing_button: "button1" })
        m("n -any", { pointing_button: "button2" })

        # position
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

    # Example: Switch between terminal windows/tabs
    # Replace with your own terminal switching script
    max = 9
    group("terminal 1-#{max}") do
      app_if(:ghostty) do
        (1..max).each { |i| m("#{i} +left_command", "#{i} +command") }
      end

      (1..max).each { |i| m("#{i} +left_option", "#{i} +command") }
    end

    # Example: Application launcher shortcuts
    group("Apps") do
      m("j +right_command", "!open -a 'Terminal'")
      m("k +right_command", "!open -a 'Safari'")
      m("semicolon +right_command", "!open -a 'Mail'")

      m("f +right_command", "!open -a 'Finder'")
      m("s +right_command", "!open -a 'Slack'")
      m("c +right_command", "!open -a 'Google Chrome'")
      m("n +right_command", "!open -a 'Notes'")

      # You can also map to other key combinations
      m("t +right_command", "t +control +command +option")
    end
  end
end

MyKaRules.new.call
