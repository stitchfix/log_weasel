# frozen_string_literal: true

module StitchFix
  module LogWeasel::Sidekiq
    LOG_WEASEL_CONTEXT_KEY = "log_weasel_id"

    def self.transaction_key
      LogWeasel.config.key ? "#{LogWeasel.config.key}-SIDEKIQ" : "SIDEKIQ"
    end

    class ClientMiddleware
      def call(_worker_class, job, _queue, _redis_pool)

        job[LOG_WEASEL_CONTEXT_KEY] = LogWeasel::Transaction.id || LogWeasel::Transaction.create(LogWeasel::Sidekiq.transaction_key)

        yield
      end
    end

    class ServerMiddleware
      def call(worker, msg, queue_name)
        if msg.has_key? LOG_WEASEL_CONTEXT_KEY
          LogWeasel::Transaction.id = msg[LOG_WEASEL_CONTEXT_KEY]
        else
          LogWeasel::Transaction.create LogWeasel::Sidekiq.transaction_key
        end

        yield
      end
    end
  end
end
