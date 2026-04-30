class API::V1::Tasks::CardsController < API::V1::Tasks::BaseController
  before_action :set_project
  before_action :set_card, only: [:show, :update, :destroy]

  def index
    records, meta = paginate(apply_updated_since(task_cards_scope(@project)))
    render_data(records.map { |card| API::V1::Serializers.task_card(card, body: markdown_body(card)) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.task_card(@card, body: markdown_body(@card)))
  end

  def create
    card = current_user.stored_files.new(folder: cards_folder_for(@project), source: :local, mime_type: "text/markdown", metadata: {"app" => "tasks", "role" => "card"})
    assign_card_attributes(card)
    return render_validation_errors(card) unless persist_card(card)

    render_data(API::V1::Serializers.task_card(card.reload, body: markdown_body(card)), status: :created)
  end

  def update
    @previous_card_filename = @card.filename.to_s
    assign_card_attributes(@card)
    return render_validation_errors(@card) unless persist_card(@card, previous_filename: @previous_card_filename)

    render_data(API::V1::Serializers.task_card(@card.reload, body: markdown_body(@card)))
  end

  def destroy
    @card.destroy!
    head :no_content
  end

  private

  def set_card
    @card = task_cards_scope(@project).find(params[:id])
  end

  def card_params
    params.require(:card).permit(:title, :body)
  end

  def assign_card_attributes(card)
    card.folder = cards_folder_for(@project)
    card.filename = markdown_filename(card_frontmatter.fetch("title", card_params[:title]))
    card.mime_type = "text/markdown"
    card.source = :local
    card.metadata = card.metadata.merge("app" => "tasks", "role" => "card")
  end

  def persist_card(card, previous_filename: nil)
    return false unless validate_card_column(card)

    StoredFile.transaction do
      return false unless persist_markdown_file(card, card_body)

      update_card_board!(card, previous_filename: previous_filename)
    end
  end

  def card_body
    @card_body ||= card_params[:body].to_s
  end

  def card_frontmatter
    @card_frontmatter ||= Tasks::CardFrontmatter.parse(card_body).frontmatter
  end

  def validate_card_column(card)
    column = card_frontmatter["column"].to_s.strip.presence
    return true if column.blank?

    unless board_columns.include?(column)
      card.errors.add(:column, "must exist on the project board")
      return false
    end

    true
  end

  def update_card_board!(card, previous_filename: nil)
    return if project_board(@project).blank?
    return if card_frontmatter["column"].blank? && previous_filename.to_s == card.filename.to_s

    board = project_board(@project)
    current_columns = board_column_paths
    previous_path = previous_filename.present? ? "cards/#{previous_filename}" : nil
    current_path = "cards/#{card.filename}"

    if (column = card_frontmatter["column"].to_s.strip.presence)
      current_columns.each_value { |paths| paths.delete(previous_path) if previous_path.present? }
      current_columns.each_value { |paths| paths.delete(current_path) }
      current_columns[column] << current_path
    elsif previous_path.present?
      current_columns.each_value do |paths|
        paths.map! { |path| (path == previous_path) ? current_path : path }
      end
    end

    persist_markdown_file(board, Tasks::BoardWriter.new(markdown_body(board)).write(current_columns))
  end

  def board_columns
    @board_columns ||= board_column_paths.keys
  end

  def board_column_paths
    @board_column_paths ||= Tasks::Board.parse(markdown_body(project_board(@project))).each_with_object({}) do |column, columns|
      columns[column.name] = column.cards.map(&:path)
    end
  end
end
