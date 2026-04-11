class InboxesController < ApplicationController
  include InboxBrowser

  allow_unauthenticated_access only: :index

  def index
    unless resume_session
      redirect_to welcome_path and return
    end

    load_inbox_browser
    if params[:outbound_message_id].present?
      @outbound_message = Current.user.outbound_messages.includes(:source_message, :domain, :conversation).find_by(id: params[:outbound_message_id])
    elsif @auto_select_first_draft && @messages.first.present?
      @outbound_message = @messages.first
    end

    # For a draft with a source message (reply/forward), show the source
    # in the thread reader so the operator sees what they're replying to
    # above the inline compose pane.
    if @mailbox == "drafts" && @outbound_message&.source_message.present?
      @selected_message = @outbound_message.source_message
      @selected_conversation = @selected_message.conversation
      @thread_timeline = @selected_conversation&.timeline_entries || []
    end
  end
end
