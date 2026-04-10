class ApplicationMailbox < ActionMailbox::Base
  routing(->(inbound_email) { Inbound::Router.match?(inbound_email) } => :inbound_message)
  routing all: :fallback
end
