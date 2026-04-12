class Drives::PhotosController < Drives::BaseController
  def index
    @selected_file = nil
    load_gallery_state
  end

  def show
    load_gallery_state
    @selected_file = @media_files.find { |stored_file| stored_file.id == params[:id].to_i }
    raise ActiveRecord::RecordNotFound, "Couldn't find StoredFile" unless @selected_file

    render :index
  end

  private

  def load_gallery_state
    @current_folder = nil
    @folders = []
    @folder_tree = Current.user.folders.order(:name).group_by(&:parent_id)
    @breadcrumb_folders = []
    @kind = normalize_kind(params[:kind])
    @media_files = media_scope.includes(:blob).gallery_ordered.to_a
    @files = @media_files
    @previous_file, @next_file = gallery_neighbors(@selected_file) if @selected_file
  end

  def media_scope
    scope = Current.user.stored_files.media
    return scope.images if @kind == "image"
    return scope.videos if @kind == "video"

    scope
  end

  def normalize_kind(value)
    value = value.to_s
    return value if %w[all image video].include?(value)

    "all"
  end

  def gallery_neighbors(selected_file)
    index = @media_files.index(selected_file)
    return [nil, nil] unless index

    previous_file = index.positive? ? @media_files[index - 1] : nil
    next_file = @media_files[index + 1]
    [previous_file, next_file]
  end
end
