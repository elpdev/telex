class Drives::BaseController < ApplicationController
  include DrivesHelper

  helper_method :current_product_area

  private

  def current_product_area
    :drive
  end
end
