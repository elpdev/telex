module Conversations
  class SubjectNormalizer
    PREFIX_PATTERN = /\A((re|aw|sv|fwd?)\s*:\s*)+/i

    def self.normalize(subject)
      value = subject.to_s.squish
      value = value.sub(PREFIX_PATTERN, "")
      value.presence || "(no subject)"
    end
  end
end
