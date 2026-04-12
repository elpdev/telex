module NotesHelper
  def note_title(stored_file)
    File.basename(stored_file.filename.to_s, ".md").presence || "UNTITLED"
  end

  def note_body(stored_file)
    return "" unless stored_file.downloadable?

    stored_file.blob.download.force_encoding("UTF-8")
  rescue
    ""
  end

  def notes_breadcrumb(folder, root_folder)
    nodes = []
    current = folder

    while current.present? && current != root_folder
      nodes.unshift(current)
      current = current.parent
    end

    nodes
  end

  def notes_folder_options_for(root_folder, folders)
    [["ROOT", root_folder.id]] + folders.reject { |folder| folder == root_folder }.map { |folder| [folder.name, folder.id] }
  end
end
