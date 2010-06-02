require 'rack/mount/utils'

module Rack::Mount
  module Generation
    module Route #:nodoc:
      def initialize(*args)
        super

        @has_significant_params = @conditions.any? { |method, condition|
          (condition.respond_to?(:required_params) && condition.required_params.any?) ||
            (condition.respond_to?(:required_defaults) && condition.required_defaults.any?)
        }
      end

      def generation_keys
        @conditions.inject({}) { |keys, (method, condition)|
          if condition.respond_to?(:required_defaults)
            keys.merge!(condition.required_defaults)
          else
            keys
          end
        }
      end

      def significant_params?
        @has_significant_params
      end

      def generate(methods, params = {}, recall = {}, options = {})
        if methods.is_a?(Array)
          result = methods.map { |m| generate_method(m, params, recall, options) || (return nil) }
        else
          result = generate_method(methods, params, recall, options)
        end

        if result
          @defaults.each do |key, value|
            params.delete(key) if params[key] == value
          end
        end

        result
      end

      private
        def generate_method(method, params, recall, options)
          if condition = @conditions[method]
            condition.generate(params, recall, options)
          end
        end
    end
  end
end
