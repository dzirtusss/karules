# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "fileutils"
require "json"
require "karules"
require "minitest/autorun"
require "tmpdir"
