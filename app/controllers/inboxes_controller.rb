class InboxesController < ApplicationController
  include InboxBrowser

  def index
    load_inbox_browser
    if params[:outbound_message_id].present?
      @outbound_message = Current.user.outbound_messages.includes(:source_message, :domain, :conversation).find_by(id: params[:outbound_message_id])
    end
  end
end
