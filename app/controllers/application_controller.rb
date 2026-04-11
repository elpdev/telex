class ApplicationController < ActionController::Base
  include Searchable
  include Authentication
  include Pagy::Method
  include Orderable

  helper_method :current_product_area

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def current_product_area
    :mail
  end
end
