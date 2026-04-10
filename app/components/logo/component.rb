# frozen_string_literal: true

class Logo::Component < ViewComponent::Base
  def app_name
    Rails.application.class.module_parent_name
  end
end
