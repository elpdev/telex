class MessageOrganizationsController < ApplicationController
  before_action :set_message

  def archive
    @message.move_to_state_for(Current.user, :archived)
    redirect_back fallback_location: root_path(mailbox: :archived)
  end

  def restore
    @message.move_to_state_for(Current.user, :inbox)
    redirect_back fallback_location: root_path
  end

  def trash
    @message.move_to_state_for(Current.user, :trash)
    redirect_back fallback_location: root_path(mailbox: :trash)
  end

  def labels
    @message.assign_labels_for(Current.user, params[:label_ids])
    redirect_back fallback_location: root_path
  end

  def mark_read
    @message.mark_read_for(Current.user)
    redirect_back fallback_location: root_path(message_id: @message.id)
  end

  def mark_unread
    @message.mark_unread_for(Current.user)
    redirect_back fallback_location: root_path(message_id: @message.id)
  end

  def star
    @message.set_starred_for(Current.user, true)
    redirect_back fallback_location: root_path(message_id: @message.id)
  end

  def unstar
    @message.set_starred_for(Current.user, false)
    redirect_back fallback_location: root_path(message_id: @message.id)
  end

  private

  def set_message
    @message = Message.find(params[:id])
  end
end
