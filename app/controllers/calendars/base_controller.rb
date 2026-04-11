class Calendars::BaseController < ApplicationController
  helper_method :current_product_area

  private

  def current_product_area
    :calendar
  end

  def calendars_scope
    Current.user.calendars.ordered
  end
end
