class OutboundMessagesController < ApplicationController
  before_action :set_message, only: [:reply, :reply_all, :forward]
  before_action :set_outbound_message, only: [:edit, :update]

  def reply
    redirect_to edit_outbound_message_path(Outbound::ReplyBuilder.create!(@message)), notice: "Reply draft created."
  end

  def reply_all
    redirect_to edit_outbound_message_path(Outbound::ReplyBuilder.create!(@message, reply_all: true)), notice: "Reply-all draft created."
  end

  def forward
    redirect_to edit_outbound_message_path(Outbound::ForwardBuilder.create!(@message, target_addresses: [])), notice: "Forward draft created."
  end

  def edit
  end

  def update
    @outbound_message.assign_attributes(outbound_message_params)

    if send_now?
      send_outbound_message
    elsif @outbound_message.save
      redirect_to edit_outbound_message_path(@outbound_message), notice: "Draft saved."
    else
      render :edit, status: :unprocessable_content
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
    render :edit, status: :unprocessable_content
  end

  def inbox_redirect_path
    source_message = @outbound_message.source_message
    return root_path unless source_message.present?

    root_path(inbox_id: source_message.inbox_id, message_id: source_message.id)
  end
end
