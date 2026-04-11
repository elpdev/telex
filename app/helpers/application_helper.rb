module ApplicationHelper
  def command_palette_domains
    return [] unless Current.user

    Domain.order(:name).to_a
  end

  def command_palette_inboxes
    return [] unless Current.user

    Inbox.includes(:domain).sort_by { |inbox| [inbox.domain.name, inbox.address] }
  end

  def command_palette_labels
    return [] unless Current.user

    Current.user.labels.order(:name).to_a
  end
end
