class API::V1::Tasks::BaseController < API::V1::BaseController
  private

  def tasks_root_folder
    @tasks_root_folder ||= current_user.folders.find_or_create_by!(parent_id: nil, name: "Tasks") do |folder|
      folder.source = :local
      folder.metadata = {"app" => "tasks", "role" => "root"}
    end
  end

  def task_projects_folder
    @task_projects_folder ||= current_user.folders.find_or_create_by!(parent: tasks_root_folder, name: "Projects") do |folder|
      folder.source = :local
      folder.metadata = {"app" => "tasks", "role" => "projects"}
    end
  end

  def all_user_folders
    @all_user_folders ||= current_user.folders.order(:name).to_a
  end

  def tasks_subtree_folders
    @tasks_subtree_folders ||= begin
      children_by_parent = all_user_folders.group_by(&:parent_id)
      folders = [tasks_root_folder]
      queue = Array(children_by_parent[tasks_root_folder.id])

      until queue.empty?
        folder = queue.shift
        folders << folder
        queue.concat(Array(children_by_parent[folder.id]))
      end

      folders
    end
  end

  def tasks_folder_ids
    @tasks_folder_ids ||= tasks_subtree_folders.map(&:id)
  end

  def task_files_scope
    current_user.stored_files.includes(:blob, :folder).where(folder_id: tasks_folder_ids, mime_type: "text/markdown")
  end

  def project_folders_scope
    task_projects_folder.children.order(:name)
  end

  def set_project
    @project = project_folders_scope.find(params[:project_id] || params[:id])
  end

  def project_manifest(project)
    task_files_scope.find_by(folder: project, filename: "project.md")
  end

  def project_board(project)
    task_files_scope.find_by(folder: project, filename: "board.md")
  end

  def cards_folder_for(project)
    project.children.find_or_create_by!(name: "cards") do |folder|
      folder.user = current_user
      folder.source = :local
      folder.metadata = {"app" => "tasks", "role" => "cards"}
    end
  end

  def task_cards_scope(project)
    task_files_scope.where(folder: cards_folder_for(project)).order(:filename)
  end

  def markdown_body(stored_file)
    return "" unless stored_file&.downloadable?

    stored_file.blob.download.force_encoding("UTF-8")
  rescue
    ""
  end

  def markdown_filename(title)
    base = title.to_s.strip.presence || "Untitled"
    base.end_with?(".md") ? base : "#{base}.md"
  end

  def build_markdown_blob(filename, body)
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(body.to_s),
      filename: filename,
      content_type: "text/markdown"
    )
  end

  def persist_markdown_file(stored_file, body)
    return false unless stored_file.valid?

    stored_file.attach_blob!(build_markdown_blob(stored_file.filename, body))
    stored_file.save
  end
end
