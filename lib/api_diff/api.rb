module ApiDiff
  class Api
    attr_accessor :classes, :interfaces, :enums

    def initialize
      @classes = []
      @interfaces = []
      @enums = []
    end

    def class(named: nil, fully_qualified_name: nil)
      classes.find { |c| c.name == named || c.fully_qualified_name == fully_qualified_name }
    end

    def interface(named: nil, fully_qualified_name: nil)
      interfaces.find { |i| i.name == named || i.fully_qualified_name == fully_qualified_name }
    end

    def enum(named: nil, fully_qualified_name: nil)
      enums.find { |e| e.name == named || e.fully_qualified_name == fully_qualified_name }
    end

    def to_s(fully_qualified_names: true)
      result = []
      result << enums.sort.map { |e| e.to_s(fully_qualified_name: fully_qualified_names) }
      result << interfaces.sort.map { |i| i.to_s(fully_qualified_name: fully_qualified_names) }
      result << classes.sort.map { |c| c.to_s(fully_qualified_name: fully_qualified_names) }
      result.flatten.join("\n\n")
    end
  end
end
