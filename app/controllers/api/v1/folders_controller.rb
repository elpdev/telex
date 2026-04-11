class API::V1::FoldersController < API::V1::BaseController
  before_action :set_folder, only: [:show, :update, :destroy]

  def index
    scope = current_user.folders.includes(:parent)
    scope = scope.where(parent_id: params[:parent_id]) if params.key?(:parent_id)
    scope = scope.where(source: params[:source]) if params[:source].present?
    scope = scope.where(provider: params[:provider]) if params[:provider].present?
    scope = apply_sort(scope, allowed: %w[created_at name updated_at], default: :name)

    records, meta = paginate(scope)
    render_data(records.map { |folder| API::V1::Serializers.folder(folder) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.folder(@folder))
  end

  def create
    folder = current_user.folders.new(folder_params)
    return render_validation_errors(folder) unless folder.save

    render_data(API::V1::Serializers.folder(folder), status: :created)
  end

  def update
    return render_validation_errors(@folder) unless @folder.update(folder_params)

    render_data(API::V1::Serializers.folder(@folder))
  end

  def destroy
    @folder.destroy!
    head :no_content
  end

  private

  def set_folder
    @folder = current_user.folders.includes(:parent).find(params[:id])
  end

  def folder_params
    params.require(:folder).permit(:parent_id, :name, :source, :provider, :provider_identifier, metadata: {})
  end
end
