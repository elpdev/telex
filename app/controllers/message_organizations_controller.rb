class MessageOrganizationsController < ApplicationController
  before_action :set_message

  def archive
    @message.move_to_state_for(Current.user, :archived)
    redirect_back fallback_location: root_path(mailbox: :archived)
  end

  def junk
    @message.move_to_junk_for(Current.user)
    redirect_back fallback_location: root_path(mailbox: :junk)
  end

  def not_junk
    @message.restore_to_inbox_for(Current.user)
    redirect_back fallback_location: root_path(message_id: @message.id)
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

  def block_sender
    update_sender_policy(:sender, :blocked)
  end

  def unblock_sender
    clear_sender_policy(:sender)
  end

  def block_domain
    update_sender_policy(:domain, :blocked)
  end

  def unblock_domain
    clear_sender_policy(:domain)
  end

  def trust_sender
    update_sender_policy(:sender, :trusted)
  end

  def untrust_sender
    clear_sender_policy(:sender, disposition: :trusted)
  end

  private

  def set_message
    @message = Message.find(params[:id])
  end

  def update_sender_policy(target_kind, disposition)
    value = sender_policy_value(target_kind)
    SenderPolicy.clear!(user: Current.user, target_kind: target_kind, value: value)
    SenderPolicy.set!(user: Current.user, target_kind: target_kind, value: value, disposition: disposition)
    redirect_back fallback_location: root_path(message_id: @message.id)
  end

  def clear_sender_policy(target_kind, disposition: nil)
    value = sender_policy_value(target_kind)
    scope = Current.user.sender_policies.where(kind: target_kind, value: value)
    scope = scope.where(disposition: disposition) if disposition.present?
    scope.destroy_all
    redirect_back fallback_location: root_path(message_id: @message.id)
  end

  def sender_policy_value(target_kind)
    case target_kind.to_sym
    when :sender
      @message.from_address.to_s.strip.downcase
    when :domain
      @message.sender_domain.to_s
    end
  end
end
