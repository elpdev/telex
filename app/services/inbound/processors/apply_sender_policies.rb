module Inbound
  module Processors
    class ApplySenderPolicies < Base
      def call
        policies = SenderPolicy.includes(:user)
        return if policies.empty?

        blocked_user_ids = []
        trusted_user_ids = []

        policies.group_by(&:user).each do |user, user_policies|
          next if user.nil?

          if user_policies.any? { |policy| policy.blocked? && policy.matches_message?(context.message) }
            context.message.move_to_junk_for(user)
            blocked_user_ids << user.id
          elsif user_policies.any? { |policy| policy.trusted? && policy.matches_message?(context.message) }
            trusted_user_ids << user.id
          end
        end

        return if blocked_user_ids.empty? && trusted_user_ids.empty?

        context.metadata["sender_policies"] = {
          "blocked_user_ids" => blocked_user_ids,
          "trusted_user_ids" => trusted_user_ids
        }.compact_blank
      end
    end
  end
end
