class API::V1::StoredFilesController < API::V1::BaseController
  include AttachmentDelivery

  before_action :set_stored_file, only: [:show, :update, :destroy, :upload, :download]

  def index
    scope = current_user.stored_files.includes(:folder, :blob, :drive_albums)
    scope = filter_folder(scope) if params.key?(:folder_id)
    scope = scope.where("filename LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s)}%") if params[:q].present?
    scope = scope.where(source: params[:source]) if params[:source].present?
    scope = scope.where(provider: params[:provider]) if params[:provider].present?
    scope = scope.where(mime_type: params[:mime_type]) if params[:mime_type].present?
    scope = apply_updated_since(scope)
    scope = apply_sort(scope, allowed: %w[byte_size created_at filename provider_updated_at updated_at], default: :filename)

    records, meta = paginate(scope)
    render_data(records.map { |stored_file| API::V1::Serializers.stored_file(stored_file) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.stored_file(@stored_file))
  end

  def create
    stored_file = current_user.stored_files.new(stored_file_params)
    stored_file.attach_direct_upload!(blob_signed_id_param) if blob_signed_id_param.present?
    return render_validation_errors(stored_file) unless persist_stored_file(stored_file)

    stored_file.reload
    render_data(API::V1::Serializers.stored_file(stored_file), status: :created)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    render_error("Invalid blob reference", status: :unprocessable_content)
  end

  def update
    @stored_file.assign_attributes(stored_file_params)
    @stored_file.attach_direct_upload!(blob_signed_id_param) if blob_signed_id_param.present?
    return render_validation_errors(@stored_file) unless persist_stored_file(@stored_file)

    @stored_file.reload
    render_data(API::V1::Serializers.stored_file(@stored_file))
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    render_error("Invalid blob reference", status: :unprocessable_content)
  end

  def upload
    return render_error("No blob reference provided", status: :bad_request) if blob_signed_id_param.blank?

    @stored_file.attach_direct_upload!(blob_signed_id_param)
    return render_validation_errors(@stored_file) unless @stored_file.save

    render_data(API::V1::Serializers.stored_file(@stored_file))
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    render_error("Invalid blob reference", status: :unprocessable_content)
  end

  def download
    return render_error("File content is not available", status: :not_found) unless @stored_file.downloadable?

    send_blob(
      @stored_file.blob,
      filename: @stored_file.filename,
      content_type: @stored_file.mime_type,
      disposition: :attachment
    )
  end

  def destroy
    @stored_file.destroy!
    head :no_content
  end

  private

  def set_stored_file
    @stored_file = current_user.stored_files.includes(:folder, :blob, :drive_albums).find(params[:id])
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

  def blob_signed_id_param
    params[:blob_signed_id].presence || params[:signed_blob_id].presence
  end

  def persist_stored_file(stored_file)
    ActiveRecord::Base.transaction do
      stored_file.save!
      sync_album_memberships!(stored_file)
    end

    true
  rescue ActiveRecord::RecordInvalid => error
    if error.record != stored_file
      stored_file.errors.add(:drive_album_ids, error.record.errors.to_hash.values.flatten.first || error.message)
    end

    false
  end

  def sync_album_memberships!(stored_file)
    return if params[:stored_file].blank? || !params[:stored_file].key?(:drive_album_ids)

    stored_file.drive_album_memberships.destroy_all
    current_user.drive_albums.where(id: album_ids_param).find_each do |album|
      stored_file.drive_album_memberships.create!(drive_album: album)
    end
  end

  def album_ids_param
    Array(params[:stored_file][:drive_album_ids]).reject(&:blank?)
  end

  def filter_folder(scope)
    return scope.where(folder_id: nil) if params[:folder_id].to_s == "root"

    scope.where(folder_id: params[:folder_id])
  end
end
