class Drives::PhotosController < Drives::BaseController
  def index
    @current_folder = nil
    @folders = []
    @files = []
    @folder_tree = Current.user.folders.where(parent_id: nil).order(:name).to_a
    @breadcrumb_folders = []
    @photo_files = Current.user.stored_files.includes(:blob).where("mime_type LIKE ?", "image/%").order(updated_at: :desc).to_a
  end
end
