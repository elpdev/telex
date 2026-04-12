class Notes::HomeController < Notes::BaseController
  def show
    @current_folder = nil
    @folders = notes_folder_tree.fetch(notes_root_folder.id, []).sort_by(&:name)
    @files = notes_files_scope.where(folder_id: notes_root_folder.id).order(:filename).to_a
    @folder_tree = notes_folder_tree
    @breadcrumb_folders = []
  end
end
