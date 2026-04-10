module Inbound
  class Pipeline
    def self.call(context, processors: context.inbox.pipeline)
      new(context, processors).call
    end

    def initialize(context, processors)
      @context = context
      @processors = processors
    end

    def call
      processors.each do |processor|
        run_processor(processor)
        break if context.halted?
      end

      context
    end

    private

    attr_reader :context, :processors

    def run_processor(processor)
      processor.call(context)
    rescue Inbound::Error
      raise
    rescue => error
      if processor.continue_on_error
        context.metadata["processor_errors"] ||= []
        context.metadata["processor_errors"] << {
          "processor" => processor.name,
          "message" => error.message
        }
      else
        raise Inbound::ProcessorError.new(processor.name, error)
      end
    end
  end
end
