require "optparse"

module ApiDiff
  class Cli
    def parse(arguments)
      parser = OptionParser.new do |opts|
        opts.on("-f", "--format FORMAT", [:swiftinterface])
        opts.on("-s", "--strip-packages")
      end
      
      options = {}
      begin
        parser.parse!(arguments, into: options)
      rescue OptionParser::ParseError => e
        raise Error.new e.message
      end

      options[:input] = arguments.pop
      
      raise Error.new "Missing argument: format" if options[:format].nil?
      raise Error.new "Missing argument: input" if options[:input].nil?

      options
    end

    def run!(arguments)
      options = parse(arguments)
      raise Error.new "Input file not found: #{options[:input]}" if not File.exist? options[:input]
      content = IO.read options[:input]

      if options[:format] == :swiftinterface
        parser = SwiftInterfaceParser.new
      end

      api = parser.parse content
      puts api.to_s
    end
  end
end
