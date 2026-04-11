class ConversationOrganizationsController < ApplicationController
  before_action :set_conversation

  def archive
    @conversation.move_to_state_for(Current.user, :archived)
    redirect_back fallback_location: root_path(mailbox: :archived)
  end

  def restore
    @conversation.move_to_state_for(Current.user, :inbox)
    redirect_back fallback_location: root_path
  end

  def trash
    @conversation.move_to_state_for(Current.user, :trash)
    redirect_back fallback_location: root_path(mailbox: :trash)
  end

  def labels
    @conversation.assign_labels_for(Current.user, params[:label_ids])
    redirect_back fallback_location: root_path
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end
end
