class InboxesController < ApplicationController
  include InboxBrowser

  def index
    load_inbox_browser
    @outbound_message = OutboundMessage.includes(:source_message, :domain, :conversation).find_by(id: params[:outbound_message_id]) if params[:outbound_message_id].present?
  end
end
