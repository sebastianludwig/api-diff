module ApiDiff
  class Parser
    def all_matches(string, regex)
      # taken from https://stackoverflow.com/a/6807722/588314
      string.to_enum(:scan, regex).map { Regexp.last_match }
    end
  end
end
