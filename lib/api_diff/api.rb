module ApiDiff
  class Api
    attr_accessor :classes, :interfaces, :enums

    def initialize
      @classes = []
      @interfaces = []
      @enums = []
    end

    def class(named:)
      classes.find { |c| c.name == named }
    end

    def interface(named:)
      interfaces.find { |i| i.name == named }
    end

    def to_s
      result = []
      result << enums.map(&:to_s)
      result << classes.map(&:to_s)
      result << interfaces.map(&:to_s)
      result.flatten.join("\n\n")
    end
  end
end
