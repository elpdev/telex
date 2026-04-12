class Drives::HomeController < Drives::BaseController
  def show
    @current_folder = nil
    @photos_mode = false
    load_browser_state
  end

  private

  def load_browser_state
    @folders = Current.user.folders.where(parent_id: nil).order(:name).to_a
    @files = Current.user.stored_files.where(folder_id: nil).includes(:blob).order(:filename).to_a
    @folder_tree = Current.user.folders.order(:name).group_by(&:parent_id)
    @breadcrumb_folders = []
  end
end
