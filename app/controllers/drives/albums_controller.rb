class Drives::AlbumsController < Drives::BaseController
  before_action :set_album, only: [:show, :edit, :update, :destroy]

  def index
    @albums = Current.user.drive_albums.order(:name).includes(:stored_files)
    load_shell_state
  end

  def show
    @kind = normalize_kind(params[:kind])
    @media_files = album_media_scope.includes(:blob).gallery_ordered.to_a
    load_shell_state
  end

  def new
    @album = Current.user.drive_albums.new
    load_shell_state
  end

  def create
    @album = Current.user.drive_albums.new(album_params)

    if @album.save
      redirect_to drives_album_path(@album), notice: "Album created"
    else
      load_shell_state
      render :new, status: :unprocessable_content
    end
  end

  def edit
    load_shell_state
  end

  def update
    if @album.update(album_params)
      redirect_to drives_album_path(@album), notice: "Album updated"
    else
      load_shell_state
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @album.destroy!
    redirect_to drives_albums_path, notice: "Album deleted"
  end

  private

  def set_album
    @album = Current.user.drive_albums.find(params[:id])
  end

  def album_params
    params.require(:drive_album).permit(:name)
  end

  def album_media_scope
    scope = @album.stored_files.media
    return scope.images if @kind == "image"
    return scope.videos if @kind == "video"

    scope
  end

  def normalize_kind(value)
    value = value.to_s
    return value if %w[all image video].include?(value)

    "all"
  end

  def load_shell_state
    @current_folder = nil
    @folders = []
    @files = defined?(@media_files) ? @media_files : []
    @folder_tree = Current.user.folders.order(:name).group_by(&:parent_id)
    @breadcrumb_folders = []
    @albums_mode = true
  end
end
