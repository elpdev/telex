class API::V1::MessageInvitationsController < API::V1::BaseController
  before_action :set_message

  def show
    render_invitation
  end

  def sync
    render_invitation
  end

  def update
    event = invitation_event
    return render_error("Invitation details could not be loaded", status: :unprocessable_content) if event.blank?

    Calendars::InvitationResponseUpdater.call(
      event: event,
      user: current_user,
      message: @message,
      participation_status: invitation_params.fetch(:participation_status)
    )

    render_data(API::V1::Serializers.invitation(@message, event: event.reload, current_user: current_user))
  end

  private

  def set_message
    @message = Message.includes(:inbox, calendar_events: [:calendar, :calendar_event_attendees, :calendar_event_links]).find(params[:id])
  end

  def invitation_event
    return unless @message.calendar_invitation?

    Calendars::InvitationSync.call(message: @message, user: current_user)
  end

  def render_invitation
    render_data(API::V1::Serializers.invitation(@message, event: invitation_event, current_user: current_user))
  end

  def invitation_params
    params.require(:invitation).permit(:participation_status)
  end
end
