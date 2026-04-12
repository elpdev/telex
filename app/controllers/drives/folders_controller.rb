class Drives::FoldersController < Drives::BaseController
  before_action :set_folder, only: [:show, :edit, :update, :destroy]

  def show
    @current_folder = @folder
    @folders = @folder.children.includes(:children, :stored_files).order(:name).to_a
    @files = @folder.stored_files.includes(:blob).order(:filename).to_a
    @folder_tree = Current.user.folders.order(:name).group_by(&:parent_id)
    @breadcrumb_folders = drive_breadcrumb(@folder)

    render "drives/home/show"
  end

  def new
    @folder = Current.user.folders.new(parent_id: params[:parent_id])
    @current_folder = resolve_current_folder(@folder.parent_id)
    @photos_mode = false
    load_shell_state
  end

  def create
    @folder = Current.user.folders.new(folder_params)

    if @folder.save
      redirect_to drive_destination_for(@folder.parent), notice: "Folder created"
    else
      @current_folder = resolve_current_folder(@folder.parent_id)
      @photos_mode = false
      load_shell_state
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @current_folder = @folder.parent
    @photos_mode = false
    load_shell_state
  end

  def update
    if @folder.update(folder_params)
      redirect_to drives_folder_path(@folder), notice: "Folder updated"
    else
      @current_folder = @folder.parent
      @photos_mode = false
      load_shell_state
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    parent = @folder.parent
    @folder.destroy!
    redirect_to drive_destination_for(parent), notice: "Folder deleted"
  end

  private

  def set_folder
    @folder = Current.user.folders.find(params[:id])
  end

  def folder_params
    params.require(:folder).permit(:parent_id, :name, :source, :provider, :provider_identifier, metadata: {})
  end

  def load_shell_state
    @folder_tree = Current.user.folders.order(:name).group_by(&:parent_id)
    @breadcrumb_folders = @current_folder.present? ? drive_breadcrumb(@current_folder) : []
  end

  def resolve_current_folder(folder_id)
    return if folder_id.blank?

    Current.user.folders.find(folder_id)
  end

  def drive_destination_for(folder)
    folder.present? ? drives_folder_path(folder) : drive_path
  end
end
