module API
  module V1
    module Serializers
      module_function

      ROUTES = Rails.application.routes.url_helpers

      def me(user)
        {
          id: user.id,
          name: user.name,
          email_address: user.email_address,
          created_at: user.created_at,
          updated_at: user.updated_at
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
          system_state: current_user.present? ? message.effective_system_state_for(current_user) : nil,
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
