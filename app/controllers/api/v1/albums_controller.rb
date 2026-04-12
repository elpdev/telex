class API::V1::AlbumsController < API::V1::BaseController
  before_action :set_album, only: [:show, :update, :destroy]

  def index
    scope = current_user.drive_albums.includes(:stored_files)
    scope = apply_sort(scope, allowed: %w[created_at name updated_at], default: :name)

    records, meta = paginate(scope)
    render_data(records.map { |album| API::V1::Serializers.drive_album(album) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.drive_album(@album))
  end

  def create
    album = current_user.drive_albums.new(album_params)
    return render_validation_errors(album) unless album.save

    render_data(API::V1::Serializers.drive_album(album), status: :created)
  end

  def update
    return render_validation_errors(@album) unless @album.update(album_params)

    render_data(API::V1::Serializers.drive_album(@album))
  end

  def destroy
    @album.destroy!
    head :no_content
  end

  private

  def set_album
    @album = current_user.drive_albums.includes(:stored_files).find(params[:id])
  end

  def album_params
    params.require(:drive_album).permit(:name)
  end
end
