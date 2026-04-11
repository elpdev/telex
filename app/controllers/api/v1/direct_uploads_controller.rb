class API::V1::DirectUploadsController < API::V1::BaseController
  def create
    ActiveStorage::Current.url_options = {
      protocol: request.protocol.delete_suffix("://"),
      host: request.host,
      port: request.optional_port
    }

    blob = ActiveStorage::Blob.create_before_direct_upload!(**direct_upload_params)
    render_data(API::V1::Serializers.direct_upload(blob), status: :created)
  ensure
    ActiveStorage::Current.url_options = nil
  end

  private

  def direct_upload_params
    params.require(:blob).permit(:filename, :byte_size, :checksum, :content_type, metadata: {}).to_h.symbolize_keys
  end
end
