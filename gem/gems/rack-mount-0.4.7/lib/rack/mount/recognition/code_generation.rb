module Rack::Mount
  module Recognition
    module CodeGeneration #:nodoc:
      def initialize(*args)
        @optimized_recognize_defined = false
        super
      end

      def _expired_recognize(env) #:nodoc:
        raise 'route set not finalized'
      end

      def rehash
        super
        optimize_recognize!
      end

      private
        def instance_variables_to_serialize
          super - [:@optimized_recognize_defined]
        end

        def expire!
          if @optimized_recognize_defined
            remove_metaclass_method :recognize

            class << self
              alias_method :recognize, :_expired_recognize
            end

            @optimized_recognize_defined = false
          end

          super
        end

        def optimize_container_iterator(container)
          body = []

          container.each_with_index { |route, i|
            body << "route = self[#{i}]"
            body << 'params = route.defaults.dup'

            conditions = []
            route.conditions.each do |method, condition|
              b = []
              if condition.is_a?(Regexp)
                b << "if m = obj.#{method}.match(#{condition.inspect})"
                if (named_captures = route.named_captures[method]) && named_captures.any?
                  b << 'matches = m.captures'
                  b << 'p = nil'
                  b << named_captures.map { |k, j| "params[#{k.inspect}] = p if p = matches[#{j}]" }.join('; ')
                end
              else
                b << "if m = obj.#{method} == route.conditions[:#{method}]"
              end
              b << 'true'
              b << 'end'
              conditions << "(#{b.join('; ')})"
            end

            body << <<-RUBY
              if #{conditions.join(' && ')}
                yield route, params
              end
            RUBY
          }

          container.instance_eval(<<-RUBY, __FILE__, __LINE__)
            def optimized_each(obj)
              #{body.join("\n")}
              nil
            end
          RUBY
        end

        def optimize_recognize!
          keys = @recognition_keys.map { |key|
            if key.is_a?(Array)
              key.call_source(:cache, :obj)
            else
              "obj.#{key}"
            end
          }.join(', ')

          @optimized_recognize_defined = true

          remove_metaclass_method :recognize

          instance_eval(<<-RUBY, __FILE__, __LINE__)
            def recognize(obj)
              cache = {}
              container = @recognition_graph[#{keys}]
              optimize_container_iterator(container) unless container.respond_to?(:optimized_each)

              if block_given?
                container.optimized_each(obj) do |route, params|
                  yield route, params
                end
              else
                container.optimized_each(obj) do |route, params|
                  return route, params
                end
              end

              nil
            end
          RUBY
        end

        # method_defined? can't distinguish between instance
        # and meta methods. So we have to rescue if the method
        # has not been defined in the metaclass yet.
        def remove_metaclass_method(symbol)
          metaclass = class << self; self; end
          metaclass.send(:remove_method, symbol)
        rescue NameError => e
          nil
        end
    end
  end
end
