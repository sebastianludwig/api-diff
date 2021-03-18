module ApiDiff
  class Function
    attr_reader :name, :signature, :return_type

    def initialize(name:, signature:, return_type:, static:, constructor:)
      @name = name
      @signature = signature
      @return_type = return_type
      @static = static
      @constructor = constructor
    end

    def is_constructor?
      @constructor
    end

    def is_static?
      @static
    end

    def to_s
      full_signature
    end

    def full_signature
      if return_type.nil?
        signature
      else
        "#{signature} -> #{return_type}"
      end
    end

    def hash
      full_signature.hash
    end

    def eql?(other)
      full_signature == other.full_signature
    end

    def <=>(other)
      # static at the bottom
      return 1 if is_static? and not other.is_static?
      return -1 if not is_static? and other.is_static?

      # constructors first
      return -1 if is_constructor? and not other.is_constructor?
      return 1 if not is_constructor? and other.is_constructor?

      if is_constructor?
        # sort constructors by length
        [full_signature.size, full_signature] <=> [other.full_signature.size, other.full_signature]
      else
        [name, full_signature] <=> [other.name, other.full_signature]
      end
    end
  end
end
