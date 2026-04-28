class API::V1::Tasks::ProjectsController < API::V1::Tasks::BaseController
  before_action :set_project, only: [:show, :update, :destroy]

  def index
    records, meta = paginate(apply_updated_since(project_folders_scope))
    render_data(records.map { |project| API::V1::Serializers.task_project(project, manifest: project_manifest(project), board: project_board(project)) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.task_project(
      @project,
      manifest: project_manifest(@project),
      board: project_board(@project),
      cards: task_cards_scope(@project).to_a
    ))
  end

  def create
    project = task_projects_folder.children.new(project_params.merge(user: current_user, source: :local, metadata: {"app" => "tasks", "role" => "project"}))
    return render_validation_errors(project) unless project.save

    create_project_files!(project)
    render_data(API::V1::Serializers.task_project(project, manifest: project_manifest(project), board: project_board(project), cards: []), status: :created)
  end

  def update
    return render_validation_errors(@project) unless @project.update(project_params)

    render_data(API::V1::Serializers.task_project(@project, manifest: project_manifest(@project), board: project_board(@project), cards: task_cards_scope(@project).to_a))
  end

  def destroy
    @project.destroy!
    head :no_content
  end

  private

  def project_params
    params.require(:project).permit(:name)
  end

  def create_project_files!(project)
    cards_folder_for(project)

    manifest = current_user.stored_files.new(
      folder: project,
      filename: "project.md",
      mime_type: "text/markdown",
      source: :local,
      metadata: {"app" => "tasks", "role" => "project"}
    )
    persist_markdown_file(manifest, "# #{project.name}\n\n")

    board = current_user.stored_files.new(
      folder: project,
      filename: "board.md",
      mime_type: "text/markdown",
      source: :local,
      metadata: {"app" => "tasks", "role" => "kanban_board"}
    )
    persist_markdown_file(board, Tasks::BoardWriter.default_markdown(project.name))
  end
end
