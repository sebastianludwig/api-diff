module ApiDiff
  class Enum < Type
    attr_accessor :cases

    def sections
      [
        cases.sort.map { |c| "case #{c}" },
        *super
      ]
    end
  end
end
