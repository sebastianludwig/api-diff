module ApiDiff
  class Parser
    attr_reader :api
    
    def initialize(options = {})
      @options = options
      @api = Api.new
    end

    protected

    def all_matches(string, regex)
      # taken from https://stackoverflow.com/a/6807722/588314
      string.to_enum(:scan, regex).map { Regexp.last_match }
    end

    def strip_packages(definition)
      return definition unless @options[:"short-names"]
      definition&.gsub(/(?:\w+\.){1,}(\w+)/, "\\1")
    end
  end
end
