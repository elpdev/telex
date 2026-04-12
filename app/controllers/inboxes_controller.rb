class InboxesController < ApplicationController
  include InboxBrowser

  before_action :set_domain, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_managed_inbox, only: [:edit, :update, :destroy]
  before_action :set_notification_recipients, only: [:new, :create, :edit, :update]

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

  def new
    @inbox = @domain.inboxes.new(active: true, pipeline_key: Inbound::PipelineRegistry.keys.first)
  end

  def create
    @inbox = @domain.inboxes.new(inbox_params)

    if @inbox.save
      redirect_to domain_path(@domain), notice: "Inbox created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @inbox.update(inbox_params)
      redirect_to domain_path(@domain), notice: "Inbox updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @inbox.destroy
    redirect_to domain_path(@domain), notice: "Inbox deleted."
  end

  private

  def set_domain
    @domain = Domain.find(params[:domain_id])
  end

  def set_managed_inbox
    @inbox = @domain.inboxes.find(params[:id])
  end

  def inbox_params
    permitted = params.require(:inbox).permit(
      :local_part,
      :pipeline_key,
      :description,
      :active,
      :forwarding_rules
    )

    permitted[:pipeline_overrides] = pipeline_overrides_params
    permitted
  end

  def pipeline_overrides_params
    overrides = (@inbox&.pipeline_overrides || {}).deep_dup
    overrides.delete("notify_user_id")

    notify_user_id = params.dig(:inbox, :notify_user_id).to_s.strip
    return overrides if notify_user_id.blank?

    overrides.merge("notify_user_id" => notify_user_id.to_i)
  end

  def set_notification_recipients
    @notification_recipients = User.order(:email_address)
  end
end
