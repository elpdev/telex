class API::V1::CapabilitiesController < API::V1::BaseController
  def show
    render_data({
      version: "v1",
      resources: {
        me: %w[show update],
        mailboxes: %w[index],
        api_keys: %w[index create show update destroy],
        labels: %w[index create show update destroy],
        sender_policies: %w[index create show update destroy],
        email_templates: %w[index create show update destroy],
        email_signatures: %w[index create show update destroy],
        calendars: %w[index create show update destroy import_ics],
        calendar_events: %w[index create show update destroy messages],
        calendar_occurrences: %w[index],
        domains: %w[index create show update destroy outbound_status validate_outbound],
        inboxes: %w[index create show update destroy pipeline test_forwarding_rules],
        messages: %w[index show body attachments inline_assets invitation sync_invitation reply reply_all forward junk not_junk archive restore trash labels mark_read mark_unread star unstar block_sender unblock_sender block_domain unblock_domain trust_sender untrust_sender],
        conversations: %w[index show timeline archive restore trash labels],
        outbound_messages: %w[index create compose show update destroy insert_template send_message queue attachments],
        notifications: %w[index show update mark_all_read],
        pipelines: %w[index show]
      },
      filters: {
        sender_policies: %w[kind disposition],
        email_templates: %w[domain_id],
        email_signatures: %w[domain_id],
        calendars: [],
        calendar_events: %w[calendar_id starts_from ends_to status source uid],
        calendar_occurrences: %w[calendar_id calendar_ids starts_from ends_to],
        domains: %w[active],
        inboxes: %w[domain_id active pipeline_key],
        messages: %w[inbox_id conversation_id status subaddress mailbox label_id q sender recipient received_from received_to],
        conversations: %w[inbox_id mailbox label_id q],
        outbound_messages: %w[domain_id conversation_id source_message_id status],
        notifications: %w[unread],
        labels: []
      },
      enums: {
        message_statuses: Message.statuses.keys,
        message_mailboxes: MessageOrganization.system_states.keys,
        conversation_mailboxes: ConversationOrganization.system_states.keys,
        outbound_message_statuses: OutboundMessage.statuses.keys,
        sender_policy_kinds: SenderPolicy.kinds.keys,
        sender_policy_dispositions: SenderPolicy.dispositions.keys,
        calendar_colors: Calendar::COLORS,
        calendar_sources: Calendar.sources.keys,
        calendar_event_sources: CalendarEvent.sources.keys,
        calendar_event_statuses: CalendarEvent.statuses.keys,
        calendar_event_participation_statuses: CalendarEventAttendee.participation_statuses.keys,
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
