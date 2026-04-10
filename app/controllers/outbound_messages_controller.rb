class OutboundMessagesController < ApplicationController
  include InboxBrowser

  before_action :set_message, only: [:reply, :reply_all, :forward]
  before_action :set_outbound_message, only: [:edit, :update]

  def create
    @outbound_message = compose_domain.outbound_messages.new(metadata: {"draft_kind" => "compose"})
    @outbound_message.body = ""
    @outbound_message.save!

    redirect_to inbox_redirect_path(outbound_message: @outbound_message), notice: "Draft created."
  end

  def reply
    redirect_to inbox_redirect_path(outbound_message: Outbound::ReplyBuilder.create!(@message), source_message: @message), notice: "Reply draft created."
  end

  def reply_all
    redirect_to inbox_redirect_path(outbound_message: Outbound::ReplyBuilder.create!(@message, reply_all: true), source_message: @message), notice: "Reply-all draft created."
  end

  def forward
    redirect_to inbox_redirect_path(outbound_message: Outbound::ForwardBuilder.create!(@message, target_addresses: []), source_message: @message), notice: "Forward draft created."
  end

  def edit
    load_compose_browser
    render "inboxes/index"
  end

  def update
    @outbound_message.assign_attributes(outbound_message_params)

    if send_now?
      send_outbound_message
    elsif @outbound_message.save
      redirect_to inbox_redirect_path(outbound_message: @outbound_message), notice: "Draft saved."
    else
      load_compose_browser
      render "inboxes/index", status: :unprocessable_content
    end
  end

  private

  def set_message
    @message = Message.find(params[:id])
  end

  def set_outbound_message
    @outbound_message = OutboundMessage.includes(:source_message, :domain).find(params[:id])
  end

  def outbound_message_params
    permitted = params.require(:outbound_message).permit(:subject, :body, :attachments, attachments: []).to_h

    permitted[:to_addresses] = split_addresses(params[:outbound_message][:to_addresses])
    permitted[:cc_addresses] = split_addresses(params[:outbound_message][:cc_addresses])
    permitted[:bcc_addresses] = split_addresses(params[:outbound_message][:bcc_addresses])
    permitted
  end

  def split_addresses(value)
    value.to_s.split(/[\n,]/).map(&:strip).reject(&:blank?)
  end

  def send_now?
    params[:send_now].present?
  end

  def send_outbound_message
    @outbound_message.enqueue_delivery!
    redirect_to inbox_redirect_path, notice: "Message queued for delivery."
  rescue ActiveRecord::RecordInvalid
    load_compose_browser
    render "inboxes/index", status: :unprocessable_content
  end

  def compose_domain
    selected_inbox = Inbox.active.find_by(id: params[:inbox_id])
    selected_inbox&.domain || Inbox.active.includes(:domain).order(:address).first&.domain
  end

  def load_compose_browser
    source_message = @outbound_message.source_message
    load_inbox_browser(selected_inbox_id: params[:inbox_id] || source_message&.inbox_id, selected_message_id: params[:message_id] || source_message&.id)
    @thread_timeline = @selected_message&.conversation&.timeline_entries || []
  end

  def inbox_redirect_path(outbound_message: nil, source_message: nil)
    source_message ||= outbound_message&.source_message || @outbound_message&.source_message

    root_path(
      inbox_id: params[:inbox_id].presence || source_message&.inbox_id,
      message_id: params[:message_id].presence || source_message&.id,
      outbound_message_id: outbound_message&.id
    )
  end
end
