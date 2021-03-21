module ApiDiff
  class Parser
    def initialize(options = {})
      @options = options
    end

    protected

    def all_matches(string, regex)
      # taken from https://stackoverflow.com/a/6807722/588314
      string.to_enum(:scan, regex).map { Regexp.last_match }
    end

    def strip_packages(definition)
      return definition unless @options[:"strip-packages"]
      definition&.gsub(/(?:\w+\.){1,}(\w+)/, "\\1")
    end
  end
end
