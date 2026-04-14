module ApplicationHelper
  def product_area_navigation_items
    [
      {key: :mail, label: "MAIL", glyph: "ML", href: root_path(mailbox: "inbox"), shortcut: "g i"},
      {key: :calendar, label: "Calendar", glyph: "CL", href: calendar_path, shortcut: "g c"},
      {key: :drive, label: "Drive", glyph: "DRV", href: drive_path, shortcut: "g v"},
      {key: :notes, label: "Notes", glyph: "NTS", href: notes_path, shortcut: "g n"}
    ]
  end

  def command_palette_commands
    [
      command_palette_mail_node,
      command_palette_calendar_node,
      command_palette_drive_node,
      command_palette_notes_node,
      command_palette_settings_node
    ]
  end

  def command_palette_domains
    return [] unless Current.user

    Current.user.domains.order(:name).to_a
  end

  def command_palette_inboxes
    return [] unless Current.user

    Current.user.inboxes.includes(:domain).sort_by { |inbox| [inbox.domain.name, inbox.address] }
  end

  def command_palette_labels
    return [] unless Current.user

    Current.user.labels.order(:name).to_a
  end

  def command_palette_global_suggestions
    [
      {label: "go mail", href: root_path(mailbox: "inbox"), hint: "APP", group: "go"},
      {label: "go calendar", href: calendar_path, hint: "APP", group: "go"},
      {label: "go drive", href: drive_path, hint: "APP", group: "go"},
      {label: "go notes", href: notes_path, hint: "APP", group: "go"},
      {label: "go profile", href: profile_path, hint: "ACCOUNT", group: "go"},
      {label: "go api keys", href: api_keys_path, hint: "API KEYS", group: "go"},
      {label: "go notifications", href: notifications_path, hint: "NOTIFICATIONS", group: "go"},
      {label: "sign out", href: session_path, hint: "DESTROY SESSION", group: "action", method: "delete"}
    ]
  end

  private

  def command_palette_mail_node
    {
      id: "mail",
      label: "mail",
      hint: "PRODUCT",
      children: [
        {
          id: "mail-browse",
          label: "browse",
          hint: "VIEWS",
          children: InboxesHelper::MAILBOXES.map do |mailbox|
            {
              id: "mail-mailbox-#{mailbox}",
              label: mailbox,
              hint: "MAILBOX",
              href: root_path(mailbox: mailbox)
            }
          end
        },
        {
          id: "mail-channels",
          label: "channels",
          hint: "INBOXES",
          children: command_palette_inboxes.map do |inbox|
            {
              id: "mail-channel-#{inbox.id}",
              label: inbox.address,
              hint: "CHANNEL",
              children: [
                {
                  id: "mail-channel-open-#{inbox.id}",
                  label: "open",
                  hint: "INBOX",
                  href: root_path(inbox_id: inbox.id, mailbox: "inbox")
                },
                {
                  id: "mail-channel-manage-#{inbox.id}",
                  label: "manage",
                  hint: "SETTINGS",
                  href: edit_domain_inbox_path(inbox.domain, inbox)
                }
              ]
            }
          end
        },
        {
          id: "mail-labels",
          label: "labels",
          hint: "FILTERS",
          children: command_palette_labels.map do |label|
            {
              id: "mail-label-#{label.id}",
              label: label.name,
              hint: "LABEL",
              href: root_path(label_id: label.id, mailbox: "inbox")
            }
          end
        },
        {
          id: "mail-domains",
          label: "domains",
          hint: "CONFIG",
          children: [
            {
              id: "mail-domains-index",
              label: "all domains",
              hint: "DOMAINS",
              href: domains_path
            },
            {
              id: "mail-domains-new",
              label: "new domain",
              hint: "CREATE",
              href: new_domain_path
            },
            *command_palette_domains.map do |domain|
              {
                id: "mail-domain-#{domain.id}",
                label: domain.name,
                hint: "DOMAIN",
                children: [
                  {
                    id: "mail-domain-manage-#{domain.id}",
                    label: "manage",
                    hint: "DOMAIN",
                    href: domain_path(domain)
                  },
                  {
                    id: "mail-domain-new-inbox-#{domain.id}",
                    label: "new inbox",
                    hint: "INBOX",
                    href: new_domain_inbox_path(domain)
                  }
                ]
              }
            end
          ]
        }
      ]
    }
  end

  def command_palette_calendar_node
    current_date = params[:date].presence || Time.zone.today

    {
      id: "calendar",
      label: "calendar",
      hint: "PRODUCT",
      children: [
        {
          id: "calendar-views",
          label: "views",
          hint: "BROWSE",
          children: %w[month week day agenda].map do |view|
            {
              id: "calendar-view-#{view}",
              label: view,
              hint: "VIEW",
              href: calendar_path(view: view, date: current_date)
            }
          end
        },
        {
          id: "calendar-actions",
          label: "actions",
          hint: "CREATE",
          children: [
            {id: "calendar-new-event", label: "new event", hint: "EVENT", href: new_calendars_event_path},
            {id: "calendar-import", label: "import ics", hint: "IMPORT", href: new_calendars_import_path},
            {id: "calendar-manage", label: "calendars", hint: "SETUP", href: calendars_calendars_path}
          ]
        }
      ]
    }
  end

  def command_palette_drive_node
    {
      id: "drive",
      label: "drive",
      hint: "PRODUCT",
      children: [
        {
          id: "drive-browse",
          label: "browse",
          hint: "FILES",
          children: [
            {id: "drive-root", label: "root", hint: "DRIVE", href: drive_path},
            {id: "drive-photos", label: "photos", hint: "MEDIA", href: drives_photos_path},
            {id: "drive-albums", label: "albums", hint: "COLLECTIONS", href: drives_albums_path}
          ]
        },
        {
          id: "drive-actions",
          label: "actions",
          hint: "CREATE",
          children: [
            {id: "drive-new-folder", label: "new folder", hint: "FOLDER", href: new_drives_folder_path},
            {id: "drive-upload", label: "upload", hint: "FILE", href: new_drives_file_path},
            {id: "drive-new-album", label: "new album", hint: "COLLECTION", href: new_drives_album_path}
          ]
        }
      ]
    }
  end

  def command_palette_settings_node
    {
      id: "settings",
      label: "settings",
      hint: "PRODUCT",
      children: [
        {
          id: "settings-account",
          label: "account",
          hint: "OPERATOR",
          children: [
            {id: "settings-profile", label: "identity", hint: "PROFILE", href: profile_path},
            {id: "settings-api-keys", label: "api keys", hint: "SECURITY", href: api_keys_path},
            {id: "settings-notifications", label: "notifications", hint: "INBOX", href: notifications_path},
            {id: "settings-sign-out", label: "sign out", hint: "SESSION", href: session_path, method: "delete"}
          ]
        },
        {
          id: "settings-workspace",
          label: "workspace",
          hint: "CONFIG",
          children: [
            {id: "settings-domains", label: "domains", hint: "MAIL", href: domains_path},
            {id: "settings-signatures", label: "signatures", hint: "MAIL", href: email_signatures_path},
            {id: "settings-templates", label: "templates", hint: "MAIL", href: email_templates_path}
          ]
        }
      ]
    }
  end

  def command_palette_notes_node
    {
      id: "notes",
      label: "notes",
      hint: "PRODUCT",
      children: [
        {
          id: "notes-browse",
          label: "browse",
          hint: "FILES",
          children: [
            {id: "notes-root", label: "root", hint: "NOTES", href: notes_path}
          ]
        },
        {
          id: "notes-actions",
          label: "actions",
          hint: "CREATE",
          children: [
            {id: "notes-new-file", label: "new note", hint: "MARKDOWN", href: new_notes_file_path},
            {id: "notes-new-folder", label: "new folder", hint: "FOLDER", href: new_notes_folder_path}
          ]
        }
      ]
    }
  end
end
