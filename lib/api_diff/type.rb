module ApiDiff
  class Type
    def self.type_name
      name.split('::').last.downcase
    end

    attr_reader :name, :fully_qualified_name
    attr_accessor :parents, :functions, :properties

    def initialize(name, fully_qualified_name)
      @name = name
      @fully_qualified_name = fully_qualified_name
      @parents = []
      @functions = []
      @properties = []
    end

    def declaration(fully_qualified_name: false)
      name = fully_qualified_name ? self.fully_qualified_name : self.name
      result = "#{self.class.type_name} #{name}"
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

    def <=>(other)
      name <=> other.name
    end

    def to_s(fully_qualified_name: true)
      body = sections.map { |s| s.empty? ? nil : s }.compact # remove empty sections
      body.map! { |s| s.map { |entry| "    #{entry}" } }  # convert every entry in every section into a string and indent it
      body.map! { |s| s.join("\n") }  # join all entries into a long string
      [
        "#{declaration(fully_qualified_name: fully_qualified_name)} {",
        body.join("\n\n"),
        "}"
      ].join("\n")
    end
  end
end
