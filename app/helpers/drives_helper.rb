module DrivesHelper
  FILE_TYPE_BADGES = {
    "application/pdf" => "PDF",
    "text/plain" => "TXT",
    "text/markdown" => "MD",
    "application/zip" => "ZIP",
    "application/x-zip-compressed" => "ZIP",
    "audio/mpeg" => "MP3",
    "audio/mp4" => "M4A",
    "video/mp4" => "MP4",
    "application/json" => "JSON"
  }.freeze

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

  def drive_previewable_image?(stored_file)
    stored_file.image? && stored_file.downloadable?
  end

  def drive_preview_badge(stored_file)
    return "IMG" if stored_file.image?

    FILE_TYPE_BADGES[stored_file.mime_type] || stored_file.filename.to_s.split(".").last.to_s.upcase.first(4).presence || "FILE"
  end

  def drive_preview_chip_class(stored_file)
    return "border-amber text-amber" if stored_file.image?
    return "border-signal text-signal" if stored_file.mime_type == "application/pdf"
    return "border-moss text-moss" if stored_file.mime_type.to_s.start_with?("audio/", "video/")

    "border-phosphor-dim text-phosphor-dim"
  end

  def drive_preview_image_tag(stored_file, size: [64, 64], class_name: nil)
    return unless drive_previewable_image?(stored_file)

    image_tag(
      stored_file.blob.variant(resize_to_fill: size),
      alt: stored_file.filename,
      class: class_name
    )
  rescue
    nil
  end

  def drive_root_path_for(folder = nil)
    folder.present? ? drives_folder_path(folder) : drive_path
  end
end
