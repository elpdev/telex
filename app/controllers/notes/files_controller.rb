class Notes::FilesController < Notes::BaseController
  before_action :set_stored_file, only: [:show, :edit, :update, :destroy]

  def show
    @current_folder = current_folder_for(@stored_file.folder)
    @folder_tree = notes_folder_tree
    @breadcrumb_folders = @current_folder.present? ? relative_notes_breadcrumb(@current_folder) : []
    @note_body = note_body(@stored_file)
  end

  def new
    @stored_file = Current.user.stored_files.new(folder: resolve_notes_folder(params[:folder_id]), source: :local, mime_type: "text/markdown")
    @current_folder = current_folder_for(@stored_file.folder)
    @folder_tree = notes_folder_tree
    @breadcrumb_folders = @current_folder.present? ? relative_notes_breadcrumb(@current_folder) : []
    @note_body = ""
  end

  def create
    @stored_file = Current.user.stored_files.new(source: :local, mime_type: "text/markdown")
    assign_note_attributes(@stored_file)

    if persist_note(@stored_file)
      redirect_to notes_file_path(@stored_file), notice: "Note created"
    else
      @current_folder = current_folder_for(@stored_file.folder)
      @folder_tree = notes_folder_tree
      @breadcrumb_folders = @current_folder.present? ? relative_notes_breadcrumb(@current_folder) : []
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @current_folder = current_folder_for(@stored_file.folder)
    @folder_tree = notes_folder_tree
    @breadcrumb_folders = @current_folder.present? ? relative_notes_breadcrumb(@current_folder) : []
    @note_body = note_body(@stored_file)
  end

  def update
    assign_note_attributes(@stored_file)

    if persist_note(@stored_file)
      redirect_to notes_file_path(@stored_file), notice: "Note updated"
    else
      @current_folder = current_folder_for(@stored_file.folder)
      @folder_tree = notes_folder_tree
      @breadcrumb_folders = @current_folder.present? ? relative_notes_breadcrumb(@current_folder) : []
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    folder = @stored_file.folder
    @stored_file.destroy!
    redirect_to (folder == notes_root_folder) ? notes_path : notes_folder_path(folder), notice: "Note deleted"
  end

  private

  def set_stored_file
    @stored_file = scoped_note_file(params[:id])
  end

  def note_params
    params.require(:stored_file).permit(:folder_id, :title, :body)
  end

  def assign_note_attributes(stored_file)
    folder = resolve_notes_folder(note_params[:folder_id])
    @note_body = note_params[:body].to_s

    stored_file.folder = folder
    stored_file.filename = note_filename(note_params[:title])
    stored_file.mime_type = "text/markdown"
    stored_file.source = :local
  end

  def persist_note(stored_file)
    return false unless stored_file.valid?

    stored_file.attach_blob!(build_markdown_blob(stored_file.filename, @note_body))
    stored_file.save
  end

  def build_markdown_blob(filename, body)
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(body.to_s),
      filename: filename,
      content_type: "text/markdown"
    )
  end

  def note_filename(title)
    base = title.to_s.strip.presence || "Untitled"
    base.end_with?(".md") ? base : "#{base}.md"
  end

  def current_folder_for(folder)
    return if folder.blank? || folder == notes_root_folder

    folder
  end
end
