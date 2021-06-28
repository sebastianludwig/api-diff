module ApiDiff
  class Api
    attr_accessor :classes, :structs, :interfaces, :enums

    def initialize
      @classes = []
      @structs = []
      @interfaces = []
      @enums = []
    end

    def class(named: nil, fully_qualified_name: nil)
      classes.find { |c| c.name == named || c.fully_qualified_name == fully_qualified_name }
    end

    def struct(named: nil, fully_qualified_name: nil)
      structs.find { |s| s.name == named || s.fully_qualified_name == fully_qualified_name }
    end

    def interface(named: nil, fully_qualified_name: nil)
      interfaces.find { |i| i.name == named || i.fully_qualified_name == fully_qualified_name }
    end

    def enum(named: nil, fully_qualified_name: nil)
      enums.find { |e| e.name == named || e.fully_qualified_name == fully_qualified_name }
    end

    def to_s(fully_qualified_names: true, order: :global)
      result = []
      if order == "global"
        result << (enums + interfaces + classes).sort.map { |e| e.to_s(fully_qualified_name: fully_qualified_names) }
      elsif order == "fqn"
        types = enums + interfaces + classes
        type_order = { "enum" => 1, "interface" => 2, "class" => 3 }
        types.sort! do |t1, t2|
          [t1.package, type_order[t1.class.type_name], t1.name] <=> [t2.package, type_order[t2.class.type_name], t2.name]
        end
        result << types.map { |e| e.to_s(fully_qualified_name: fully_qualified_names) }
      else
        result << enums.sort.map { |e| e.to_s(fully_qualified_name: fully_qualified_names) }
        result << interfaces.sort.map { |i| i.to_s(fully_qualified_name: fully_qualified_names) }
        result << classes.sort.map { |c| c.to_s(fully_qualified_name: fully_qualified_names) }
      end
      result.flatten.join("\n\n")
    end
  end
end
