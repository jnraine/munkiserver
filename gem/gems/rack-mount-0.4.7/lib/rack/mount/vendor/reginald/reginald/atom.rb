module Reginald
  class Atom < Struct.new(:value)
    attr_accessor :ignorecase

    def initialize(*args)
      @ignorecase = nil
      super
    end

    # Returns true if expression could be treated as a literal string.
    def literal?
      false
    end

    def casefold?
      ignorecase ? true : false
    end

    def to_s(parent = false)
      "#{value}"
    end

    def inspect #:nodoc:
      "#<#{self.class.to_s.sub('Reginald::', '')} #{to_s.inspect}>"
    end

    def ==(other) #:nodoc:
      case other
      when String
        other == to_s
      else
        eql?(other)
      end
    end

    def eql?(other) #:nodoc:
      other.instance_of?(self.class) &&
        self.value.eql?(other.value) &&
        (!!self.ignorecase).eql?(!!other.ignorecase)
    end

    def freeze #:nodoc:
      value.freeze
      super
    end
  end
end
