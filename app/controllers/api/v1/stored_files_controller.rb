class API::V1::StoredFilesController < API::V1::BaseController
  before_action :set_stored_file, only: [:show, :update, :destroy]

  def index
    scope = current_user.stored_files.includes(:folder, :blob)
    scope = scope.where(folder_id: params[:folder_id]) if params.key?(:folder_id)
    scope = scope.where(source: params[:source]) if params[:source].present?
    scope = scope.where(provider: params[:provider]) if params[:provider].present?
    scope = scope.where(mime_type: params[:mime_type]) if params[:mime_type].present?
    scope = apply_sort(scope, allowed: %w[byte_size created_at filename provider_updated_at updated_at], default: :filename)

    records, meta = paginate(scope)
    render_data(records.map { |stored_file| API::V1::Serializers.stored_file(stored_file) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.stored_file(@stored_file))
  end

  def create
    stored_file = current_user.stored_files.new(stored_file_params)
    return render_validation_errors(stored_file) unless stored_file.save

    render_data(API::V1::Serializers.stored_file(stored_file), status: :created)
  end

  def update
    return render_validation_errors(@stored_file) unless @stored_file.update(stored_file_params)

    render_data(API::V1::Serializers.stored_file(@stored_file))
  end

  def destroy
    @stored_file.destroy!
    head :no_content
  end

  private

  def set_stored_file
    @stored_file = current_user.stored_files.includes(:folder, :blob).find(params[:id])
  end

  def stored_file_params
    params.require(:stored_file).permit(
      :folder_id,
      :source,
      :provider,
      :provider_identifier,
      :active_storage_blob_id,
      :filename,
      :mime_type,
      :byte_size,
      :provider_created_at,
      :provider_updated_at,
      :image_width,
      :image_height,
      metadata: {}
    )
  end
end
