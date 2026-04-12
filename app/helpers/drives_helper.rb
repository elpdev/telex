module DrivesHelper
  def drive_breadcrumb(folder)
    nodes = []
    current = folder

    while current.present?
      nodes.unshift(current)
      current = current.parent
    end

    nodes
  end

  def drive_location_label(record)
    return "ROOT" if record.root?

    record.parent&.name.to_s.upcase
  end

  def drive_kind_label(entry)
    entry.is_a?(Folder) ? "FOLDER" : "FILE"
  end

  def drive_source_label(entry)
    parts = [entry.source.to_s.upcase]
    parts << entry.provider.to_s.upcase if entry.respond_to?(:provider) && entry.provider.present?
    parts.join(" :: ")
  end

  def drive_size_label(stored_file)
    return "-" if stored_file.byte_size.blank?

    number_to_human_size(stored_file.byte_size)
  end

  def drive_updated_label(entry)
    entry.updated_at.strftime("%Y-%m-%d %H:%M")
  end

  def drive_status_label(stored_file)
    stored_file.downloadable? ? "READY" : "METADATA ONLY"
  end

  def drive_root_path_for(folder = nil)
    folder.present? ? drives_folder_path(folder) : drive_path
  end
end
