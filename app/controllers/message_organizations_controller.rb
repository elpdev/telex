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

  private

  def set_message
    @message = Message.find(params[:id])
  end
end
