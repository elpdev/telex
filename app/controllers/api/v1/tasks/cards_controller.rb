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
    return render_validation_errors(card) unless persist_markdown_file(card, card_params[:body])

    render_data(API::V1::Serializers.task_card(card.reload, body: markdown_body(card)), status: :created)
  end

  def update
    assign_card_attributes(@card)
    return render_validation_errors(@card) unless persist_markdown_file(@card, card_params[:body])

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
    card.filename = markdown_filename(card_params[:title])
    card.mime_type = "text/markdown"
    card.source = :local
    card.metadata = card.metadata.merge("app" => "tasks", "role" => "card")
  end
end
