class WelcomeNotifier < Noticed::Event
  notification_methods do
    def message
      "Welcome! Your account has been created."
    end

    def url
      root_path
    end
  end
end
