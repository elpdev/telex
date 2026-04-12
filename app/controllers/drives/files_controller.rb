class Drives::FilesController < Drives::BaseController
  include AttachmentDelivery

  before_action :set_stored_file, only: [:show, :edit, :update, :destroy, :download]

  def show
    redirect_to drive_destination_for(@stored_file.folder)
  end

  def new
    @stored_file = Current.user.stored_files.new(folder_id: params[:folder_id], source: :local)
    @current_folder = resolve_current_folder(@stored_file.folder_id)
    @photos_mode = false
    load_shell_state
  end

  def create
    @stored_file = Current.user.stored_files.new(stored_file_params)
    @stored_file.attach_direct_upload!(params[:blob_signed_id]) if params[:blob_signed_id].present?

    if @stored_file.save
      redirect_to drive_destination_for(@stored_file.folder), notice: "File uploaded"
    else
      @current_folder = resolve_current_folder(@stored_file.folder_id)
      @photos_mode = false
      load_shell_state
      render :new, status: :unprocessable_content
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    @stored_file.errors.add(:base, "Invalid direct upload reference")
    @current_folder = resolve_current_folder(@stored_file.folder_id)
    load_shell_state
    render :new, status: :unprocessable_content
  end

  def edit
    @current_folder = @stored_file.folder
    @photos_mode = false
    load_shell_state
  end

  def update
    @stored_file.assign_attributes(stored_file_params)
    @stored_file.attach_direct_upload!(params[:blob_signed_id]) if params[:blob_signed_id].present?

    if @stored_file.save
      redirect_to drive_destination_for(@stored_file.folder), notice: "File updated"
    else
      @current_folder = @stored_file.folder
      @photos_mode = false
      load_shell_state
      render :edit, status: :unprocessable_content
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    @stored_file.errors.add(:base, "Invalid direct upload reference")
    @current_folder = @stored_file.folder
    @photos_mode = false
    load_shell_state
    render :edit, status: :unprocessable_content
  end

  def destroy
    folder = @stored_file.folder
    @stored_file.destroy!
    redirect_to drive_destination_for(folder), notice: "File deleted"
  end

  def download
    return redirect_to drive_destination_for(@stored_file.folder), alert: "File content is not available" unless @stored_file.downloadable?

    send_blob(
      @stored_file.blob,
      filename: @stored_file.filename,
      content_type: @stored_file.mime_type,
      disposition: :attachment
    )
  end

  private

  def set_stored_file
    @stored_file = Current.user.stored_files.includes(:blob).find(params[:id])
  end

  def stored_file_params
    params.require(:stored_file).permit(
      :folder_id,
      :source,
      :provider,
      :provider_identifier,
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

  def load_shell_state
    @folder_tree = Current.user.folders.where(parent_id: nil).order(:name).to_a
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
