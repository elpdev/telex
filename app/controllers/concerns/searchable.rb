module Searchable
  extend ActiveSupport::Concern

  private

  def search(scope)
    @q = scope.ransack(params[:q])
    @q.result(distinct: true)
  end
end
