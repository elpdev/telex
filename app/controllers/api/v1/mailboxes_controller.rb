class API::V1::MailboxesController < API::V1::BaseController
  def index
    render_data({
      mailboxes: mailbox_payload,
      labels: current_user.labels.order(:name).map { |label| API::V1::Serializers.label(label) },
      inboxes: Inbox.with_message_count_for(user: current_user).active.order(:address).map { |inbox| API::V1::Serializers.inbox(inbox) },
      domains: Domain.order(:name).map { |domain| API::V1::Serializers.domain(domain) }
    })
  end

  private

  def mailbox_payload
    %w[inbox junk archived trash].map do |mailbox|
      API::V1::Serializers.mailbox(mailbox, count: Message.in_mailbox_for(current_user, mailbox).joins(:inbox).merge(Inbox.active).count)
    end + [
      API::V1::Serializers.mailbox("sent", count: current_user.outbound_messages.sent.count),
      API::V1::Serializers.mailbox("drafts", count: current_user.outbound_messages.draft.count)
    ]
  end
end
