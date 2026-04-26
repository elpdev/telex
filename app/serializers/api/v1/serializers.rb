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
          user_id: domain.user_id,
          drive_folder_id: domain.drive_folder_id,
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
          drive_folder_id: inbox.drive_folder_id,
          effective_drive_folder_id: inbox.effective_drive_folder&.id,
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

      def folder(folder)
        {
          id: folder.id,
          user_id: folder.user_id,
          parent_id: folder.parent_id,
          name: folder.name,
          source: folder.source,
          provider: folder.provider,
          provider_identifier: folder.provider_identifier,
          metadata: folder.metadata,
          created_at: folder.created_at,
          updated_at: folder.updated_at
        }
      end

      def drive_album_summary(album)
        {
          id: album.id,
          name: album.name
        }
      end

      def drive_album(album)
        {
          id: album.id,
          user_id: album.user_id,
          name: album.name,
          stored_file_ids: album.stored_files.media.ids,
          media_file_count: album.stored_files.media.count,
          created_at: album.created_at,
          updated_at: album.updated_at
        }
      end

      def stored_file(stored_file)
        payload = {
          id: stored_file.id,
          user_id: stored_file.user_id,
          folder_id: stored_file.folder_id,
          active_storage_blob_id: stored_file.active_storage_blob_id,
          filename: stored_file.filename,
          mime_type: stored_file.mime_type,
          byte_size: stored_file.byte_size,
          source: stored_file.source,
          provider: stored_file.provider,
          provider_identifier: stored_file.provider_identifier,
          provider_created_at: stored_file.provider_created_at,
          provider_updated_at: stored_file.provider_updated_at,
          metadata: stored_file.metadata,
          drive_album_ids: stored_file.drive_album_ids,
          drive_albums: stored_file.drive_albums.order(:name).map { |album| drive_album_summary(album) },
          local_blob: stored_file.local_blob?,
          downloadable: stored_file.downloadable?,
          image_metadata: stored_file.image_metadata,
          created_at: stored_file.created_at,
          updated_at: stored_file.updated_at
        }

        payload[:download_url] = ROUTES.download_api_v1_file_path(stored_file) if stored_file.downloadable?
        payload[:upload_url] = ROUTES.upload_api_v1_file_path(stored_file)
        payload
      end

      def note(stored_file)
        {
          id: stored_file.id,
          user_id: stored_file.user_id,
          folder_id: stored_file.folder_id,
          title: File.basename(stored_file.filename.to_s, ".md").presence || "UNTITLED",
          filename: stored_file.filename,
          mime_type: stored_file.mime_type,
          folder: notes_folder_summary(stored_file.folder),
          body: note_body(stored_file),
          created_at: stored_file.created_at,
          updated_at: stored_file.updated_at
        }
      end

      def notes_folder_tree(folder, children_by_parent:, note_counts: {})
        children = Array(children_by_parent[folder.id]).sort_by(&:name)

        notes_folder_summary(folder).merge(
          note_count: note_counts.fetch(folder.id, 0),
          child_folder_count: children.size,
          children: children.map do |child|
            notes_folder_tree(child, children_by_parent: children_by_parent, note_counts: note_counts)
          end
        )
      end

      def notes_folder_summary(folder)
        return if folder.blank?

        {
          id: folder.id,
          user_id: folder.user_id,
          parent_id: folder.parent_id,
          name: folder.name,
          source: folder.source,
          metadata: folder.metadata,
          created_at: folder.created_at,
          updated_at: folder.updated_at
        }
      end

      def direct_upload(blob)
        {
          signed_id: blob.signed_id,
          filename: blob.filename.to_s,
          byte_size: blob.byte_size,
          checksum: blob.checksum,
          content_type: blob.content_type,
          metadata: blob.metadata,
          direct_upload: {
            url: blob.service_url_for_direct_upload,
            headers: blob.service_headers_for_direct_upload
          }
        }
      end

      def contact(contact, include_note: false)
        payload = {
          id: contact.id,
          user_id: contact.user_id,
          contact_type: contact.contact_type,
          name: contact.name,
          company_name: contact.company_name,
          title: contact.title,
          phone: contact.phone,
          website: contact.website,
          display_name: contact.display_name,
          primary_email_address: contact.primary_email_address&.email_address,
          email_addresses: contact.email_addresses.sort_by { |email| [email.primary_address? ? 0 : 1, email.email_address] }.map { |email| contact_email_address(email) },
          note_file_id: contact.note_file_id,
          metadata: contact.metadata,
          created_at: contact.created_at,
          updated_at: contact.updated_at
        }

        payload[:note] = contact_note(contact, Contacts::NoteFile.read(contact)) if include_note
        payload
      end

      def contact_summary(contact)
        return if contact.blank?

        {
          id: contact.id,
          contact_type: contact.contact_type,
          display_name: contact.display_name,
          primary_email_address: contact.primary_email_address&.email_address
        }
      end

      def contact_email_address(email_address)
        {
          id: email_address.id,
          email_address: email_address.email_address,
          label: email_address.label,
          primary_address: email_address.primary_address,
          created_at: email_address.created_at,
          updated_at: email_address.updated_at
        }
      end

      def contact_note(contact, note)
        stored_file = note[:stored_file]

        {
          contact_id: contact.id,
          stored_file_id: stored_file&.id,
          title: note[:title],
          body: note[:body],
          created_at: stored_file&.created_at,
          updated_at: stored_file&.updated_at
        }
      end

      def contact_communication(communication)
        record = communication.communicable

        {
          id: communication.id,
          contact_id: communication.contact_id,
          kind: record.model_name.singular,
          communicable_type: communication.communicable_type,
          communicable_id: communication.communicable_id,
          occurred_at: communication.occurred_at,
          metadata: communication.metadata,
          communication: contact_communication_record(record),
          created_at: communication.created_at,
          updated_at: communication.updated_at
        }
      end

      def note_body(stored_file)
        return "" unless stored_file.downloadable?

        stored_file.blob.download.force_encoding("UTF-8")
      rescue
        ""
      end

      def message(message, current_user: nil)
        {
          id: message.id,
          inbox_id: message.inbox_id,
          conversation_id: message.conversation_id,
          message_id: message.message_id,
          from_address: message.from_address,
          from_name: message.from_name,
          contact: contact_summary(message.contact),
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
          inbox_id: outbound_message.inbox_id,
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

      def contact_communication_record(record)
        case record
        when Message
          message_summary(record)
        when OutboundMessage
          {
            id: record.id,
            domain_id: record.domain_id,
            inbox_id: record.inbox_id,
            conversation_id: record.conversation_id,
            subject: record.subject,
            to_addresses: record.to_addresses,
            cc_addresses: record.cc_addresses,
            bcc_addresses: record.bcc_addresses,
            preview_text: record.body_text.squish.presence || "No preview available",
            status: record.status,
            sent_at: record.sent_at,
            created_at: record.created_at
          }
        end
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
