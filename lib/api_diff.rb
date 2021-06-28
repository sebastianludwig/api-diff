require "api_diff/version"
require "api_diff/api"
require "api_diff/type"
require "api_diff/class"
require "api_diff/struct"
require "api_diff/interface"
require "api_diff/enum"
require "api_diff/function"
require "api_diff/property"
require "api_diff/parser"
require "api_diff/swift_interface_parser"
require "api_diff/kotlin_bcv_parser"
require "api_diff/cli"

module ApiDiff
  class Error < StandardError; end
end
