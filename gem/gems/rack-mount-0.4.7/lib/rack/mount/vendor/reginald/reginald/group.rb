module Reginald
  class Group < Struct.new(:expression)
    attr_accessor :quantifier, :capture, :index, :name

    def initialize(*args)
      @capture = true
      super
    end

    def ignorecase=(ignorecase)
      expression.ignorecase = ignorecase
    end

    # Returns true if expression could be treated as a literal string.
    #
    # A Group is literal if its expression is literal and it has no quantifier.
    def literal?
      quantifier.nil? && expression.literal?
    end

    def to_s(parent = false)
      if expression.options == 0
        "(#{capture ? '' : '?:'}#{expression.to_s(parent)})#{quantifier}"
      elsif capture == false
        "#{expression.to_s}#{quantifier}"
      else
        "(#{expression.to_s})#{quantifier}"
      end
    end

    def to_regexp
      Regexp.compile("\\A#{to_s}\\Z")
    end

    def inspect #:nodoc:
      to_s.inspect
    end

    def match(char)
      to_regexp.match(char)
    end

    def include?(char)
      expression.include?(char)
    end

    def capture?
      capture
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
      other.is_a?(self.class) &&
        self.expression == other.expression &&
        self.quantifier == other.quantifier &&
        self.capture == other.capture &&
        self.index == other.index &&
        self.name == other.name
    end

    def freeze #:nodoc:
      expression.freeze
      super
    end
  end
end
