module Inbound
  module Processors
    class ReceiptParser < Base
      def call
        context.metadata["receipt_parser"] = "pending"
      end
    end
  end
end
