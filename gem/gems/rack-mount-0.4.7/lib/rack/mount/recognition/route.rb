require 'rack/mount/utils'

module Rack::Mount
  module Recognition
    module Route #:nodoc:
      attr_reader :named_captures

      def initialize(*args)
        super

        @named_captures = {}
        @conditions.map { |method, condition|
          next unless condition.respond_to?(:named_captures)
          @named_captures[method] = condition.named_captures.inject({}) { |named_captures, (k, v)|
            named_captures[k.to_sym] = v.last - 1
            named_captures
          }.freeze
        }
        @named_captures.freeze
      end

      def recognize(obj)
        params = @defaults.dup
        if @conditions.all? { |method, condition|
          value = obj.send(method)
          if condition.is_a?(Regexp) && (m = value.match(condition))
            matches = m.captures
            @named_captures[method].each { |k, i|
              if v = matches[i]
                params[k] = v
              end
            }
            true
          elsif value == condition
            true
          else
            false
          end
        }
          params
        else
          nil
        end
      end
    end
  end
end
