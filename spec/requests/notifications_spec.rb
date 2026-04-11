require "rails_helper"

RSpec.describe "Notifications", type: :request do
  describe "POST /notifications/mark_all_read" do
    it "marks all unread notifications as read" do
      user = create(:user)
      login_user(user)

      WelcomeNotifier.with({}).deliver(user)
      WelcomeNotifier.with({}).deliver(user)
      user.notifications.order(:id).first.mark_as_read!

      post mark_all_read_notifications_path

      expect(response).to redirect_to(notifications_path)
      expect(user.notifications.unread.count).to eq(0)
      expect(user.notifications.read.count).to eq(2)
    end
  end
end
