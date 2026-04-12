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

  def drive_gallery_timestamp(stored_file)
    stored_file.provider_created_at || stored_file.created_at
  end

  def drive_gallery_date_label(stored_file)
    drive_gallery_timestamp(stored_file).strftime("%Y-%m-%d %H:%M")
  end

  def drive_gallery_filter_label(kind)
    return "ALL MEDIA" if kind == "all"
    return "IMAGES" if kind == "image"
    return "VIDEOS" if kind == "video"

    "MEDIA"
  end

  def drive_gallery_scope_label(album)
    return "PHOTOS" if album.blank?

    album.name.upcase
  end

  def drive_gallery_scope_caption(album)
    return "Media gallery" if album.blank?

    "Album"
  end

  def drive_gallery_path(kind:, album: nil)
    drives_photos_path({kind: kind}.merge(album.present? ? {album_id: album.id} : {}))
  end

  def drive_gallery_preview_path(stored_file, kind:, album: nil)
    drives_photo_path(stored_file, {kind: kind}.merge(album.present? ? {album_id: album.id} : {}))
  end

  def drive_album_options_for(user)
    user.drive_albums.order(:name).map { |album| [album.name, album.id] }
  end

  def drive_status_label(stored_file)
    stored_file.downloadable? ? "READY" : "METADATA ONLY"
  end

  def drive_previewable_image?(stored_file)
    stored_file.image? && stored_file.downloadable?
  end

  def drive_previewable_video?(stored_file)
    stored_file.video? && stored_file.downloadable?
  end

  def drive_preview_kind(stored_file)
    return :image if drive_previewable_image?(stored_file)
    return :video if drive_previewable_video?(stored_file)
    return :pdf if stored_file.mime_type == "application/pdf" && stored_file.downloadable?
    return :audio if stored_file.mime_type.to_s.start_with?("audio/") && stored_file.downloadable?
    return :text if drive_text_previewable?(stored_file)

    :none
  end

  def drive_preview_available?(stored_file)
    drive_preview_kind(stored_file) != :none
  end

  def drive_preview_badge(stored_file)
    return "IMG" if stored_file.image?

    FILE_TYPE_BADGES[stored_file.mime_type] || stored_file.filename.to_s.split(".").last.to_s.upcase.first(4).presence || "FILE"
  end

  def drive_folder_badge
    "DIR"
  end

  def drive_folder_chip_class
    "border-amber text-amber"
  end

  def drive_folder_item_label(folder)
    count = folder.children.size + folder.stored_files.size
    count.zero? ? "EMPTY" : pluralize(count, "item").upcase
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

  def drive_preview_video_tag(stored_file, class_name: nil, controls: false)
    return unless drive_previewable_video?(stored_file)

    video_tag(
      url_for(stored_file.blob),
      class: class_name,
      controls: controls,
      preload: "metadata",
      playsinline: true,
      muted: !controls
    )
  end

  def drive_inline_blob_url(stored_file)
    return unless stored_file.downloadable?

    rails_blob_path(stored_file.blob, disposition: "inline")
  end

  def drive_text_previewable?(stored_file)
    stored_file.downloadable? && stored_file.mime_type.in?(%w[text/plain text/markdown application/json]) && stored_file.byte_size.to_i <= 200.kilobytes
  end

  def drive_text_preview(stored_file)
    return unless drive_text_previewable?(stored_file)

    stored_file.blob.download.force_encoding("UTF-8")
  rescue
    nil
  end

  def drive_root_path_for(folder = nil)
    folder.present? ? drives_folder_path(folder) : drive_path
  end

  def drive_folder_options_for(user)
    [["ROOT", nil]] + user.folders.order(:name).map { |folder| [folder.name, folder.id] }
  end

  def drive_folder_tree(folder_tree, current_folder)
    build_drive_folder_tree(folder_tree, nil, current_folder)
  end

  private

  def build_drive_folder_tree(folder_tree, parent_id, current_folder)
    Array(folder_tree[parent_id]).map do |folder|
      {
        folder: folder,
        active: folder == current_folder,
        current_branch: current_folder.present? && drive_breadcrumb(current_folder).include?(folder),
        children: build_drive_folder_tree(folder_tree, folder.id, current_folder)
      }
    end
  end
end
