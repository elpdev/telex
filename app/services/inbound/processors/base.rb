module Inbound
  module Processors
    class Base
      class_attribute :continue_on_error, default: false, instance_accessor: false

      def self.call(context)
        new(context).call
      end

      def self.continue_on_error!
        self.continue_on_error = true
      end

      attr_reader :context

      def initialize(context)
        @context = context
      end

      private

      def halt!
        context.halt!
      end
    end
  end
end
