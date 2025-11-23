# karules

Configure Karabiner-Elements with Ruby DSL - cleaner, more maintainable keyboard customization for macOS.

## What is this?

If you're like me and have a complex Karabiner-Elements configuration, you probably know the pain of editing that giant JSON file manually. I got tired of it and wrote a Ruby DSL to generate the config instead.

**Features:**
- Clean, readable Ruby syntax instead of JSON
- Group related mappings together
- Reusable helper methods
- Application-specific rules
- Modal keyboard modes
- No need to remember Karabiner's JSON structure

## Why?

Karabiner-Elements is powerful but its configuration format is...verbose. Here's a simple caps lock → control mapping:

**JSON (what Karabiner wants):**
```json
{
  "description": "Caps Lock to Control",
  "manipulators": [{
    "type": "basic",
    "from": {
      "key_code": "caps_lock",
      "modifiers": { "optional": ["any"] }
    },
    "to": [{ "key_code": "left_control" }]
  }]
}
```

**Ruby (what you write):**
```ruby
group("Caps Lock") do
  m("caps_lock -any", "left_control")
end
```

Much better.

## Installation

### Via Homebrew (soon)

```bash
brew tap dzirtusss/tap
brew install karules
```

### Via RubyGems

```bash
gem install karules
```

### Manual

```bash
git clone https://github.com/dzirtusss/karules.git
cd karules
gem build karules.gemspec
gem install karules-0.1.0.gem
```

## Configuration

Create your config file at `~/.config/karules/config.rb`:

```ruby
require "karules"

class MyConfig < KaRules
  def config
    # Define your apps
    apps(
      slack: "^com\\.tinyspeck\\.slackmacgap$",
      terminal: "^com\\.apple\\.Terminal$"
    )

    # Simple mapping
    group("Caps Lock") do
      m("caps_lock -any", "left_control")
    end

    # App-specific rules
    group("Slack shortcuts") do
      app_if(:slack) do
        m("h +right_option", "left_arrow")
        m("l +right_option", "right_arrow")
      end
    end

    # Launch apps
    group("App launcher") do
      m("t +right_command", "!open -a 'Terminal'")
      m("s +right_command", "!open -a 'Safari'")
    end

    # Modal modes (vim-style)
    group("Tab mode") do
      m("tab", "right_option lazy", to_if_alone: "tab")
      m("j +right_option", "down_arrow")
      m("k +right_option", "up_arrow")
      m("h +right_option", "left_arrow")
      m("l +right_option", "right_arrow")
    end
  end
end

MyConfig.new.call
```

Then run:

```bash
karules
```

It will update your `~/.config/karabiner/karabiner.json` automatically.

## Usage

### Basic Mapping

```ruby
m("from_key", "to_key")
```

### Modifiers

**Mandatory modifiers** (must be pressed):
```ruby
m("a +command", "b")  # Command+A → B
```

**Optional modifiers** (can be pressed):
```ruby
m("a -any", "b")  # A (with any modifiers) → B
```

### Shell Commands

```ruby
m("t +command", "!open -a 'Terminal'")
```

### Application-Specific Rules

```ruby
apps(slack: "^com\\.tinyspeck\\.slackmacgap$")

app_if(:slack) do
  m("j +control", "down_arrow")
end
```

### Complex Mappings

```ruby
m("a +control",
  to: "b",
  to_if_alone: "escape",
  conditions: some_condition)
```

### Modal Modes

Create vim-like modal keyboards:

```ruby
group("Vi Mode") do
  default_mode("vi-mode")

  # Enter mode
  m("escape", mode_on)

  # Exit on any non-vi key
  m("escape", mode_off)

  # Mappings only active in mode
  mode_if do
    m("h", "left_arrow")
    m("j", "down_arrow")
    m("k", "up_arrow")
    m("l", "right_arrow")
  end
end
```

### Custom Karabiner Path

```ruby
def config
  karabiner_path "~/custom/karabiner.json"
  # ... rest of config
end
```

## Tips

**Use groups** to organize your config:
```ruby
group("Navigation") do
  # related mappings
end

group("App Launcher") do
  # related mappings
end
```

**Extract common patterns** into methods:
```ruby
def vim_nav(prefix)
  m("h #{prefix}", "left_arrow")
  m("j #{prefix}", "down_arrow")
  m("k #{prefix}", "up_arrow")
  m("l #{prefix}", "right_arrow")
end

group("Vim nav") do
  vim_nav("+option")
end
```

**Check the example** config for more ideas:
- See the [example config](examples/config.rb)
- Or run: `gem contents karules | grep examples`

## How It Works

1. You write Ruby DSL in `~/.config/karules/config.rb`
2. Run `karules` command
3. It generates the JSON rules
4. Updates your Karabiner config
5. Karabiner picks up the changes automatically

The DSL is just Ruby, so you can:
- Use variables and loops
- Write helper methods
- Split config into multiple files (with `load`)
- Generate mappings programmatically

## Troubleshooting

**Config not loading?**

Make sure your config file is at:
- `~/.config/karules/config.rb` (default)
- Or specify: `karules /path/to/config.rb`

**Changes not applying?**

Karabiner should detect changes automatically. If not:
- Check Karabiner-EventViewer for errors
- Verify your JSON at `~/.config/karabiner/karabiner.json`
- Restart Karabiner-Elements

**Syntax errors?**

Your config is Ruby code. Check for:
- Missing `do`/`end` blocks
- Unmatched quotes
- Typos in method names

## Comparison with Alternatives

**JSON (built-in):** Maximum control but verbose and error-prone

**Goku/KarabinerDSL:** Great alternatives! This is just my take with Ruby instead of Clojure/other DSLs. Use whatever works for you.

**Why Ruby?** Because I write Ruby daily and wanted something that feels natural to me. If you prefer other languages, check out the alternatives.

## Known Limitations

- This is an early version, expect some rough edges
- Not all Karabiner features are wrapped (but you can use raw hashes for anything)
- No validation yet (invalid configs will fail at Karabiner level)
- Examples use my personal workflow - adapt to yours

## Future Ideas

- [ ] Config validation before writing
- [ ] Interactive config generator
- [ ] More helper methods for common patterns
- [ ] Better error messages
- [ ] Support for multiple profiles

PRs welcome!

## License

MIT - see [LICENSE](LICENSE)

## Credits

Built with frustration and coffee by [@dzirtusss](https://github.com/dzirtusss)

Inspired by everyone who's ever looked at a Karabiner JSON file and thought "there must be a better way."
