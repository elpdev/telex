module API
  module V1
    module Serializers
      module_function

      ROUTES = Rails.application.routes.url_helpers

      def me(user)
        payload = {
          id: user.id,
          name: user.name,
          email_address: user.email_address,
          created_at: user.created_at,
          updated_at: user.updated_at
        }

        if user.avatar.attached?
          payload[:avatar] = {
            filename: user.avatar.filename.to_s,
            content_type: user.avatar.content_type,
            byte_size: user.avatar.byte_size,
            url: ROUTES.rails_blob_path(user.avatar, only_path: true)
          }
        end

        payload
      end

      def mailbox(name, count:)
        {
          name: name,
          count: count
        }
      end

      def api_key(api_key, secret_key: nil)
        payload = {
          id: api_key.id,
          name: api_key.name,
          client_id: api_key.client_id,
          expires_at: api_key.expires_at,
          expired: api_key.expired?,
          last_used_at: api_key.last_used_at,
          last_used_ip: api_key.last_used_ip,
          created_at: api_key.created_at,
          updated_at: api_key.updated_at
        }
        payload[:secret_key] = secret_key if secret_key.present?
        payload
      end

      def domain(domain)
        {
          id: domain.id,
          name: domain.name,
          active: domain.active,
          outbound_from_name: domain.outbound_from_name,
          outbound_from_address: domain.outbound_from_address,
          use_from_address_for_reply_to: domain.use_from_address_for_reply_to,
          reply_to_address: domain.reply_to_address,
          smtp_host: domain.smtp_host,
          smtp_port: domain.smtp_port,
          smtp_authentication: domain.smtp_authentication,
          smtp_enable_starttls_auto: domain.smtp_enable_starttls_auto,
          smtp_username: domain.smtp_username,
          outbound_ready: domain.outbound_ready?,
          outbound_configuration_errors: domain.outbound_configuration_errors,
          outbound_identity: domain.outbound_identity,
          created_at: domain.created_at,
          updated_at: domain.updated_at
        }
      end

      def inbox(inbox)
        {
          id: inbox.id,
          domain_id: inbox.domain_id,
          address: inbox.address,
          local_part: inbox.local_part,
          pipeline_key: inbox.pipeline_key,
          pipeline_overrides: inbox.pipeline_overrides,
          forwarding_rules: inbox.forwarding_rules,
          active_forwarding_rules: inbox.active_forwarding_rules,
          description: inbox.description,
          active: inbox.active,
          message_count: inbox.message_count,
          created_at: inbox.created_at,
          updated_at: inbox.updated_at
        }
      end

      def label(label)
        {
          id: label.id,
          name: label.name,
          color: label.color,
          created_at: label.created_at,
          updated_at: label.updated_at
        }
      end

      def sender_policy(sender_policy)
        {
          id: sender_policy.id,
          kind: sender_policy.kind,
          disposition: sender_policy.disposition,
          value: sender_policy.value,
          created_at: sender_policy.created_at,
          updated_at: sender_policy.updated_at
        }
      end

      def email_template(email_template)
        {
          id: email_template.id,
          domain_id: email_template.domain_id,
          name: email_template.name,
          subject: email_template.subject,
          body_html: email_template.body.to_s,
          body_text: email_template.body.to_plain_text,
          created_at: email_template.created_at,
          updated_at: email_template.updated_at
        }
      end

      def email_signature(email_signature)
        {
          id: email_signature.id,
          domain_id: email_signature.domain_id,
          name: email_signature.name,
          is_default: email_signature.is_default,
          body_html: email_signature.body.to_s,
          body_text: email_signature.body.to_plain_text,
          created_at: email_signature.created_at,
          updated_at: email_signature.updated_at
        }
      end

      def calendar(calendar)
        {
          id: calendar.id,
          user_id: calendar.user_id,
          name: calendar.name,
          color: calendar.color,
          time_zone: calendar.time_zone,
          position: calendar.position,
          source: calendar.source,
          created_at: calendar.created_at,
          updated_at: calendar.updated_at
        }
      end

      def calendar_event_attendee(attendee)
        {
          id: attendee.id,
          email: attendee.email,
          name: attendee.name,
          role: attendee.role,
          participation_status: attendee.participation_status,
          response_requested: attendee.response_requested,
          created_at: attendee.created_at,
          updated_at: attendee.updated_at
        }
      end

      def calendar_event_link(link)
        {
          id: link.id,
          message_id: link.message_id,
          ical_uid: link.ical_uid,
          ical_method: link.ical_method,
          sequence_number: link.sequence_number,
          created_at: link.created_at,
          updated_at: link.updated_at
        }
      end

      def calendar_event(event, include_messages: false, current_user: nil)
        payload = {
          id: event.id,
          calendar_id: event.calendar_id,
          title: event.title,
          description: event.description,
          location: event.location,
          all_day: event.all_day,
          starts_at: event.starts_at,
          ends_at: event.ends_at,
          time_zone: event.time_zone,
          effective_time_zone: event.effective_time_zone,
          status: event.status,
          source: event.source,
          uid: event.uid,
          organizer_name: event.organizer_name,
          organizer_email: event.organizer_email,
          recurrence_rule: event.recurrence_rule,
          recurrence_summary: event.recurrence_summary,
          recurrence_exceptions: event.recurrence_exceptions,
          sequence_number: event.sequence_number,
          invitation: event.invitation?,
          next_occurrences: event.next_occurrences(limit: 8).map(&:iso8601),
          attendees: event.calendar_event_attendees.order(:email).map { |attendee| calendar_event_attendee(attendee) },
          links: event.calendar_event_links.order(created_at: :desc).map { |link| calendar_event_link(link) },
          created_at: event.created_at,
          updated_at: event.updated_at
        }

        if current_user.present?
          attendee = event.attendee_for_addresses([current_user.email_address])
          payload[:current_user_attendee] = attendee.present? ? calendar_event_attendee(attendee) : nil
        end

        if include_messages
          payload[:messages] = event.invitation_messages.map { |message| message_summary(message, current_user: current_user) }
        end

        payload
      end

      def calendar_occurrence(occurrence, current_user: nil)
        {
          starts_at: occurrence.starts_at,
          ends_at: occurrence.ends_at,
          all_day: occurrence.all_day,
          event: calendar_event(occurrence.event, current_user: current_user)
        }
      end

      def invitation(message, event:, current_user:)
        attendee = event&.attendee_for_addresses([current_user.email_address, message.inbox.address, *message.to_addresses])

        {
          message_id: message.id,
          available: message.calendar_invitation?,
          invitation_data: message.calendar_invitation_data,
          calendar_event: event.present? ? calendar_event(event, include_messages: true, current_user: current_user) : nil,
          current_user_attendee: attendee.present? ? calendar_event_attendee(attendee) : nil
        }
      end

      def message_summary(message, current_user: nil)
        {
          id: message.id,
          inbox_id: message.inbox_id,
          conversation_id: message.conversation_id,
          subject: message.subject,
          from_address: message.from_address,
          from_name: message.from_name,
          sender_display: message.sender_display,
          preview_text: message.preview_text,
          received_at: message.received_at,
          system_state: current_user.present? ? message.effective_system_state_for(current_user) : nil
        }
      end

      def message(message, current_user: nil)
        {
          id: message.id,
          inbox_id: message.inbox_id,
          conversation_id: message.conversation_id,
          message_id: message.message_id,
          from_address: message.from_address,
          from_name: message.from_name,
          sender_display: message.sender_display,
          to_addresses: message.to_addresses,
          cc_addresses: message.cc_addresses,
          subject: message.subject,
          subaddress: message.subaddress,
          status: message.status,
          preview_text: message.preview_text,
          text_body: message.text_body,
          html_email: message.html_email?,
          metadata: message.metadata,
          read: current_user.present? ? message.read_for?(current_user) : nil,
          read_at: current_user.present? ? message.read_at_for(current_user) : nil,
          starred: current_user.present? ? message.starred_for?(current_user) : nil,
          system_state: current_user.present? ? message.effective_system_state_for(current_user) : nil,
          sender_blocked: current_user.present? ? message.sender_blocked_for?(current_user) : nil,
          sender_trusted: current_user.present? ? message.sender_trusted_for?(current_user) : nil,
          domain_blocked: current_user.present? ? message.domain_blocked_for?(current_user) : nil,
          labels: current_user.present? ? message.labels_for(current_user).map { |label| self.label(label) } : [],
          received_at: message.received_at,
          created_at: message.created_at,
          updated_at: message.updated_at,
          attachments: message.attachments.map { |record| attachment_payload(record, parent: message, api: true) }
        }
      end

      def outbound_message(outbound_message)
        {
          id: outbound_message.id,
          domain_id: outbound_message.domain_id,
          source_message_id: outbound_message.source_message_id,
          conversation_id: outbound_message.conversation_id,
          to_addresses: outbound_message.to_addresses,
          cc_addresses: outbound_message.cc_addresses,
          bcc_addresses: outbound_message.bcc_addresses,
          subject: outbound_message.subject,
          body_html: outbound_message.body.to_s,
          body_text: outbound_message.body_text,
          status: outbound_message.status,
          delivery_attempts: outbound_message.delivery_attempts,
          mail_message_id: outbound_message.mail_message_id,
          in_reply_to_message_id: outbound_message.in_reply_to_message_id,
          reference_message_ids: outbound_message.reference_message_ids,
          metadata: outbound_message.metadata,
          last_error: outbound_message.last_error,
          queued_at: outbound_message.queued_at,
          sent_at: outbound_message.sent_at,
          failed_at: outbound_message.failed_at,
          created_at: outbound_message.created_at,
          updated_at: outbound_message.updated_at,
          attachments: outbound_message.attachments.map { |record| attachment_payload(record, parent: outbound_message, api: true) }
        }
      end

      def conversation(conversation, current_user: nil)
        {
          id: conversation.id,
          subject_key: conversation.subject_key,
          participant_addresses: conversation.participant_addresses,
          system_state: current_user.present? ? conversation.effective_system_state_for(current_user) : nil,
          labels: current_user.present? ? conversation.labels_for(current_user).map { |label| self.label(label) } : [],
          last_message_at: conversation.last_message_at,
          created_at: conversation.created_at,
          updated_at: conversation.updated_at,
          message_count: conversation.messages.size,
          outbound_message_count: conversation.outbound_messages.size
        }
      end

      def conversation_timeline_entry(entry)
        record = entry[:record]

        {
          kind: entry[:kind],
          record_id: record.id,
          occurred_at: entry[:occurred_at],
          sender: entry[:sender],
          recipients: entry[:recipients],
          summary: entry[:summary],
          status: entry[:status],
          subject: record.subject,
          conversation_id: record.conversation_id
        }
      end

      def notification(notification)
        {
          id: notification.id,
          type: notification.type,
          message: notification.respond_to?(:message) ? notification.message : nil,
          url: notification.respond_to?(:url) ? notification.url : nil,
          read_at: notification.read_at,
          created_at: notification.created_at,
          updated_at: notification.updated_at
        }
      end

      def pipeline(key)
        processors = Inbound::PipelineRegistry.fetch(key)

        {
          key: key,
          processors: processors.map(&:name)
        }
      end

      def attachment_payload(attachment, parent:, api: false)
        payload = {
          id: attachment.id,
          filename: attachment.filename.to_s,
          content_type: attachment.content_type,
          byte_size: attachment.blob.byte_size,
          created_at: attachment.created_at,
          previewable: AttachmentPreview.previewable?(attachment),
          preview_kind: AttachmentPreview.preview_kind(attachment)
        }

        payload[:preview_url] = attachment_preview_path(parent, attachment, api: api) if payload[:previewable]
        payload[:download_url] = attachment_download_path(parent, attachment, api: api)
        payload
      end

      def attachment_preview_path(parent, attachment, api: false)
        if parent.is_a?(Message)
          api ? ROUTES.api_v1_message_attachment_path(parent, attachment) : ROUTES.message_attachment_path(parent, attachment)
        else
          api ? ROUTES.api_v1_outbound_message_attachment_path(parent, attachment) : ROUTES.outbound_message_attachment_path(parent, attachment)
        end
      end

      def attachment_download_path(parent, attachment, api: false)
        if parent.is_a?(Message)
          api ? ROUTES.download_api_v1_message_attachment_path(parent, attachment) : ROUTES.download_message_attachment_path(parent, attachment)
        else
          api ? ROUTES.download_api_v1_outbound_message_attachment_path(parent, attachment) : ROUTES.download_outbound_message_attachment_path(parent, attachment)
        end
      end
    end
  end
end
