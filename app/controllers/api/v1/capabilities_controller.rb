class API::V1::CapabilitiesController < API::V1::BaseController
  def show
    render_data({
      version: "v1",
      resources: {
        me: %w[show update],
        api_keys: %w[index create show update destroy],
        labels: %w[index create show update destroy],
        domains: %w[index create show update destroy outbound_status validate_outbound],
        inboxes: %w[index create show update destroy pipeline test_forwarding_rules],
        messages: %w[index show body attachments inline_assets reply reply_all forward archive restore trash labels],
        conversations: %w[index show timeline archive restore trash labels],
        outbound_messages: %w[index create show update destroy send_message queue attachments],
        notifications: %w[index show update mark_all_read],
        pipelines: %w[index show]
      },
      filters: {
        domains: %w[active],
        inboxes: %w[domain_id active pipeline_key],
        messages: %w[inbox_id conversation_id status subaddress mailbox label_id q],
        conversations: %w[inbox_id mailbox label_id q],
        outbound_messages: %w[domain_id conversation_id source_message_id status],
        notifications: %w[unread],
        labels: []
      },
      enums: {
        message_statuses: Message.statuses.keys,
        message_mailboxes: MessageOrganization.system_states.keys + ["sent"],
        conversation_mailboxes: ConversationOrganization.system_states.keys,
        outbound_message_statuses: OutboundMessage.statuses.keys,
        smtp_authentication_methods: Domain::SMTP_AUTHENTICATION_METHODS,
        pipeline_keys: Inbound::PipelineRegistry.keys
      },
      pagination: {
        page_param: "page",
        per_page_param: "per_page",
        max_per_page: 100
      }
    })
  end
end
