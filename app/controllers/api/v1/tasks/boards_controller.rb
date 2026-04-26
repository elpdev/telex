class API::V1::Tasks::BoardsController < API::V1::Tasks::BaseController
  before_action :set_project
  before_action :set_board

  def show
    render_data(API::V1::Serializers.task_board(@board, columns: board_columns, cards_by_path: cards_by_path))
  end

  def update
    @board.filename = "board.md"
    @board.mime_type = "text/markdown"
    @board.source = :local
    @board.metadata = @board.metadata.merge("app" => "tasks", "role" => "kanban_board")

    return render_validation_errors(@board) unless persist_markdown_file(@board, board_params[:body])

    render_data(API::V1::Serializers.task_board(@board.reload, columns: board_columns, cards_by_path: cards_by_path))
  end

  private

  def set_board
    @board = project_board(@project) || current_user.stored_files.new(folder: @project, filename: "board.md", mime_type: "text/markdown", source: :local)
  end

  def board_params
    params.require(:board).permit(:body)
  end

  def board_columns
    @board_columns ||= Tasks::Board.parse(markdown_body(@board))
  end

  def cards_by_path
    @cards_by_path ||= task_cards_scope(@project).index_by { |card| "cards/#{card.filename}" }
  end
end
