class MessageInvitationsController < ApplicationController
  def update
    message = Message.find(params[:id])
    event = Calendars::InvitationSync.call(message: message, user: Current.user)

    if event.blank?
      redirect_to root_path(inbox_id: message.inbox_id, message_id: message.id), alert: "Invitation details could not be loaded."
      return
    end

    Calendars::InvitationResponseUpdater.call(
      event: event,
      user: Current.user,
      message: message,
      participation_status: invitation_params.fetch(:participation_status)
    )

    redirect_to root_path(inbox_id: message.inbox_id, message_id: message.id), notice: "Invitation response updated."
  end

  private

  def invitation_params
    params.require(:invitation).permit(:participation_status)
  end
end
