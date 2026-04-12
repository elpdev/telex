class Notes::FoldersController < Notes::BaseController
  before_action :set_folder, only: [:show, :edit, :update, :destroy]

  def show
    @current_folder = (@folder == notes_root_folder) ? nil : @folder
    @folders = @folder.children.order(:name).to_a
    @files = notes_files_scope.where(folder_id: @folder.id).order(:filename).to_a
    @folder_tree = notes_folder_tree
    @breadcrumb_folders = relative_notes_breadcrumb(@folder)

    render "notes/home/show"
  end

  def new
    @folder = Current.user.folders.new(parent_id: params[:parent_id].presence || notes_root_folder.id, source: :local)
    @current_folder = current_folder_for(@folder.parent_id)
    @folder_tree = notes_folder_tree
    @breadcrumb_folders = @current_folder.present? ? relative_notes_breadcrumb(@current_folder) : []
  end

  def create
    @folder = Current.user.folders.new(folder_params.merge(source: :local))
    @folder.parent = resolve_notes_folder(@folder.parent_id)

    if @folder.save
      redirect_to notes_destination_for(@folder.parent), notice: "Folder created"
    else
      @current_folder = current_folder_for(@folder.parent_id)
      @folder_tree = notes_folder_tree
      @breadcrumb_folders = @current_folder.present? ? relative_notes_breadcrumb(@current_folder) : []
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @current_folder = current_folder_for(@folder.parent_id)
    @folder_tree = notes_folder_tree
    @breadcrumb_folders = @current_folder.present? ? relative_notes_breadcrumb(@current_folder) : []
  end

  def update
    @folder.assign_attributes(folder_params)
    @folder.parent = resolve_notes_folder(@folder.parent_id)

    if @folder.save
      redirect_to notes_folder_path(@folder), notice: "Folder updated"
    else
      @current_folder = current_folder_for(@folder.parent_id)
      @folder_tree = notes_folder_tree
      @breadcrumb_folders = @current_folder.present? ? relative_notes_breadcrumb(@current_folder) : []
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    parent = @folder.parent
    @folder.destroy!
    redirect_to notes_destination_for(parent), notice: "Folder deleted"
  end

  private

  def set_folder
    @folder = scoped_notes_folder(params[:id])
  end

  def folder_params
    params.require(:folder).permit(:parent_id, :name)
  end

  def current_folder_for(folder_id)
    folder = resolve_notes_folder(folder_id)
    (folder == notes_root_folder) ? nil : folder
  end

  def notes_destination_for(folder)
    return notes_path if folder.blank? || folder == notes_root_folder

    notes_folder_path(folder)
  end
end
