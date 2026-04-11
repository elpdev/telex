class API::V1::NotificationsController < API::V1::BaseController
  before_action :set_notification, only: [:show, :update]

  def index
    scope = current_user.notifications.newest_first
    scope = scope.unread if truthy_param?(params[:unread])
    records, meta = paginate(scope)

    render_data(records.map { |notification| API::V1::Serializers.notification(notification) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.notification(@notification))
  end

  def update
    @notification.mark_as_read!
    render_data(API::V1::Serializers.notification(@notification.reload))
  end

  def mark_all_read
    current_user.notifications.unread.find_each(&:mark_as_read!)
    render_data({marked_all_read: true})
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
