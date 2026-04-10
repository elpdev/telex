class ProcessMessageJob < ApplicationJob
  queue_as :inbound

  retry_on Inbound::RetryableError, attempts: 5, wait: :polynomially_longer
  discard_on Inbound::NonRetryableError

  def perform(message)
    message.update!(status: :processing, processing_error: nil)

    context = Inbound::PipelineContext.new(
      inbound_email: message.inbound_email,
      inbox: message.inbox,
      message: message,
      subaddress: message.subaddress,
      metadata: message.metadata
    )

    Inbound::Pipeline.call(context)

    message.update!(status: :processed, metadata: context.metadata, processing_error: nil)
  rescue => error
    message.update!(status: :failed, metadata: context&.metadata || message.metadata, processing_error: "#{error.class}: #{error.message}")
    raise
  end
end
