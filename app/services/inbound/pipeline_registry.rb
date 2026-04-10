module Inbound
  class PipelineRegistry
    PIPELINES = {
      "default" => [
        Inbound::Processors::StoreAndCategorize,
        Inbound::Processors::Forward,
        Inbound::Processors::Notify
      ],
      "receipts" => [
        Inbound::Processors::StoreAndCategorize,
        Inbound::Processors::ReceiptParser,
        Inbound::Processors::Forward,
        Inbound::Processors::Notify
      ]
    }.freeze

    def self.fetch(key)
      PIPELINES.fetch(key.to_s) do
        raise Inbound::NonRetryableError, "Unknown pipeline: #{key}"
      end
    end

    def self.keys
      PIPELINES.keys
    end
  end
end
