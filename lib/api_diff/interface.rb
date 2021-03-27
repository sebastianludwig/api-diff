module ApiDiff
  class Interface < Type
    def self.type_name
      @type_name || super
    end
    
    def self.type_name=(name)
      @type_name = name
    end
  end
end
