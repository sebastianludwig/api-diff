require "optparse"

module ApiDiff
  class Cli
    def parse(arguments)
      parser = OptionParser.new do |opts|
        opts.on("-f", "--format FORMAT", ["swift-interface", "kotlin-bcv"])
        opts.on("-s", "--strip-packages")
        opts.on("-n", "--normalize")
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

      if options[:format] == "swift-interface"
        parser = SwiftInterfaceParser.new(options)
      elsif options[:format] == "kotlin-bcv"
        parser = KotlinBCVParser.new(options)
      end

      api = parser.parse(IO.read(options[:input]))
      puts api.to_s
    end
  end
end
