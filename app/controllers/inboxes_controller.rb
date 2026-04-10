class InboxesController < ApplicationController
  before_action :load_sidebar_inboxes

  def index
    @selected_inbox = selected_inbox_from_sidebar
    @all_inboxes_count = Message.joins(:inbox).merge(Inbox.active).count

    scope = Message
      .joins(:inbox)
      .merge(Inbox.active)
      .includes(inbox: :domain)
      .with_rich_text_body
      .with_attached_attachments
      .newest_first

    scope = scope.where(inbox: @selected_inbox) if @selected_inbox.present?

    @q = scope.ransack(search_params)
    filtered_scope = @q.result(distinct: true)
    @pagy, paginated_scope = pagy(filtered_scope, limit: 18)
    @messages = paginated_scope.to_a
    @selected_message = selected_message_from(filtered_scope)
  end

  private

  def load_sidebar_inboxes
    @inboxes = Inbox
      .active
      .left_joins(:messages)
      .select("inboxes.*, COUNT(messages.id) AS message_count")
      .group("inboxes.id")
      .order(:address)
      .to_a
  end

  def selected_inbox_from_sidebar
    return if params[:inbox_id].blank?

    @inboxes.find { |inbox| inbox.id == params[:inbox_id].to_i }
  end

  def selected_message_from(filtered_scope)
    return @messages.first if params[:message_id].blank?

    @messages.find { |message| message.id == params[:message_id].to_i } || filtered_scope.find_by(id: params[:message_id]) || @messages.first
  end

  def search_params
    permitted = params.fetch(:q, {}).permit(:status_eq, :subaddress_eq, :subject_or_from_address_or_from_name_or_text_body_cont).to_h

    if permitted["status_eq"].present?
      permitted["status_eq"] = Message.statuses[permitted["status_eq"]]
    end

    permitted
  end
end
