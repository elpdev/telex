module Contacts
  class NoteFile
    def self.read(contact)
      new(contact).read
    end

    def self.write!(contact, title:, body:)
      new(contact).write!(title: title, body: body)
    end

    def initialize(contact)
      @contact = contact
    end

    def read
      stored_file = contact.note_file

      {
        stored_file: stored_file,
        title: title_for(stored_file),
        body: body_for(stored_file)
      }
    end

    def write!(title:, body:)
      stored_file = contact.note_file || build_note_file(title: title)
      stored_file.folder = contacts_root_folder
      stored_file.filename = note_filename(title.presence || contact.display_name)
      stored_file.mime_type = "text/markdown"
      stored_file.source = :local
      stored_file.metadata = stored_file.metadata.merge("app" => "contacts", "role" => "contact_note", "contact_id" => contact.id)
      stored_file.attach_blob!(build_markdown_blob(stored_file.filename, body.to_s))
      stored_file.save!

      contact.update!(note_file: stored_file) if contact.note_file_id != stored_file.id
      read
    end

    private

    attr_reader :contact

    def build_note_file(title:)
      contact.user.stored_files.new(
        folder: contacts_root_folder,
        source: :local,
        mime_type: "text/markdown",
        filename: note_filename(title.presence || contact.display_name),
        metadata: {"app" => "contacts", "role" => "contact_note", "contact_id" => contact.id}
      )
    end

    def contacts_root_folder
      @contacts_root_folder ||= contact.user.folders.find_or_create_by!(parent_id: nil, name: "Contacts") do |folder|
        folder.source = :local
        folder.metadata = {"app" => "contacts", "role" => "root"}
      end
    end

    def build_markdown_blob(filename, body)
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(body.to_s),
        filename: filename,
        content_type: "text/markdown"
      )
    end

    def body_for(stored_file)
      return "" unless stored_file&.downloadable?

      stored_file.blob.download.force_encoding("UTF-8")
    rescue
      ""
    end

    def title_for(stored_file)
      return contact.display_name if stored_file.blank?

      File.basename(stored_file.filename.to_s, ".md").presence || contact.display_name
    end

    def note_filename(title)
      base = title.to_s.strip.presence || "Untitled"
      base.end_with?(".md") ? base : "#{base}.md"
    end
  end
end
