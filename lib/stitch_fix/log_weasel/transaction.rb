require "ulid"

module StitchFix
  module LogWeasel
    module Transaction

      # UUIDs are from iOS and Android
      UUID_REGEX_FORM = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}-(?<scope>.+)/i # https://rubular.com/r/9XYz1jiWqZVpA1
      ULID_REGEX_FORM = /[0-9a-z]{26}-(?<scope>.+)/i # https://rubular.com/r/4NjnyWRZVtz1gf

      def self.create(key = nil)
        Thread.current[:log_weasel_id] = "#{ULID.generate}#{key ? "-#{key}" : ""}"
      end

      def self.destroy
        Thread.current[:log_weasel_id] = nil
      end

      def self.id=(id)
        Thread.current[:log_weasel_id] = id
      end

      def self.id
        Thread.current[:log_weasel_id]
      end

      def self.scope
        return unless self.id
        match_data = self.id.match(ULID_REGEX_FORM) || self.id.match(UUID_REGEX_FORM)

        match_data[:scope].downcase if match_data && match_data[:scope]
      end
    end
  end
end
