module ApiDiff
  class Type
    attr_reader :name
    attr_accessor :parents, :functions, :properties

    def initialize(name)
      @name = name
      @parents = []
      @functions = []
      @properties = []
    end

    def declaration
      kind = self.class.name.split('::').last.downcase
      result = "#{kind} #{name}"
      result += " : #{parents.join(", ")}" if has_parents?
      result
    end

    def has_parents?
      not @parents.empty?
    end

    def sections
      [
        properties.sort,
        functions.sort
      ]
    end

    def to_s
      body = sections.map { |s| s.empty? ? nil : s }.compact # remove empty sections
      body.map! { |s| s.map { |entry| "    #{entry}" } }  # convert every entry in every section into a string and indent it
      body.map! { |s| s.join("\n") }  # join all entries into a long string
      [
        "#{declaration} {",
        body.join("\n\n"),
        "}"
      ].join("\n")
    end
  end
end
