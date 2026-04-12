class API::V1::NotesController < API::V1::BaseController
  class InvalidNotesFolder < StandardError; end

  rescue_from InvalidNotesFolder, with: :render_invalid_notes_folder

  before_action :set_note, only: [:show, :update, :destroy]

  def index
    folder = params.key?(:folder_id) ? resolve_notes_folder!(params[:folder_id]) : notes_root_folder
    scope = notes_files_scope.includes(:folder, :blob).where(folder_id: folder.id)
    scope = apply_sort(scope, allowed: %w[created_at filename updated_at], default: :filename)

    records, meta = paginate(scope)
    render_data(records.map { |note| API::V1::Serializers.note(note) }, meta: meta)
  end

  def tree
    render_data(API::V1::Serializers.notes_folder_tree(notes_root_folder, children_by_parent: notes_children_by_parent, note_counts: notes_file_counts_by_folder))
  end

  def show
    render_data(API::V1::Serializers.note(@note))
  end

  def create
    note = current_user.stored_files.new(source: :local, mime_type: "text/markdown")
    assign_note_attributes(note)
    return render_validation_errors(note) unless persist_note(note)

    note.reload
    render_data(API::V1::Serializers.note(note), status: :created)
  end

  def update
    assign_note_attributes(@note)
    return render_validation_errors(@note) unless persist_note(@note)

    @note.reload
    render_data(API::V1::Serializers.note(@note))
  end

  def destroy
    @note.destroy!
    head :no_content
  end

  private

  def set_note
    @note = notes_files_scope.includes(:folder, :blob).find(params[:id])
  end

  def note_params
    params.require(:note).permit(:folder_id, :title, :body)
  end

  def assign_note_attributes(note)
    note.folder = resolve_notes_folder!(note_params[:folder_id])
    note.filename = note_filename(note_params[:title])
    note.mime_type = "text/markdown"
    note.source = :local
    @note_body = note_params[:body].to_s
  end

  def persist_note(note)
    return false unless note.valid?

    note.attach_blob!(build_markdown_blob(note.filename, @note_body))
    note.save
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

  def notes_root_folder
    @notes_root_folder ||= current_user.folders.find_or_create_by!(parent_id: nil, name: "Notes") do |folder|
      folder.source = :local
      folder.metadata = {"app" => "notes", "role" => "root"}
    end
  end

  def notes_subtree_folders
    @notes_subtree_folders ||= begin
      children_by_parent = current_user.folders.order(:name).to_a.group_by(&:parent_id)
      folders = [notes_root_folder]
      queue = Array(children_by_parent[notes_root_folder.id])

      until queue.empty?
        folder = queue.shift
        folders << folder
        queue.concat(Array(children_by_parent[folder.id]))
      end

      folders
    end
  end

  def notes_folder_ids
    @notes_folder_ids ||= notes_subtree_folders.map(&:id)
  end

  def notes_files_scope
    current_user.stored_files.where(folder_id: notes_folder_ids, mime_type: "text/markdown")
  end

  def notes_children_by_parent
    @notes_children_by_parent ||= notes_subtree_folders.group_by(&:parent_id)
  end

  def notes_file_counts_by_folder
    @notes_file_counts_by_folder ||= notes_files_scope.group(:folder_id).count
  end

  def resolve_notes_folder!(folder_id)
    return notes_root_folder if folder_id.blank?

    folder = current_user.folders.find_by(id: folder_id)
    raise InvalidNotesFolder if folder.blank? || !notes_folder_ids.include?(folder.id)

    folder
  end

  def render_invalid_notes_folder
    render json: {
      error: "Validation failed",
      details: {folder_id: ["Folder must be within the Notes workspace"]}
    }, status: :unprocessable_content
  end
end
