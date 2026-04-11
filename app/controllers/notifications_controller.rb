class NotificationsController < ApplicationController
  before_action :set_notification, only: :update

  def index
    @notifications = Current.user.notifications.newest_first
  end

  def update
    @notification.mark_as_read!
    redirect_to @notification.url || notifications_path
  end

  def mark_all_read
    Current.user.notifications.unread.mark_as_read
    redirect_to notifications_path, notice: "All notifications marked as read."
  end

  private

  def set_notification
    @notification = Current.user.notifications.find(params[:id])
  end
end
