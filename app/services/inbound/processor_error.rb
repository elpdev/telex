module Inbound
  class ProcessorError < NonRetryableError
    attr_reader :processor_name

    def initialize(processor_name, cause)
      @processor_name = processor_name
      super("#{processor_name} failed: #{cause.message}")
      set_backtrace(cause.backtrace)
    end
  end
end
