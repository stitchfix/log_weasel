require 'rails'

module StitchFix
  class LogWeasel::Railtie < Rails::Railtie
    config.log_weasel = ActiveSupport::OrderedOptions.new # enable namespaced configuration in Rails environments

    initializer "log_weasel.configure" do |app|
      LogWeasel.configure do |config|
        config.key = app.config.log_weasel[:key] || LogWeasel::Railtie.app_name.upcase
      end

      app.config.middleware.insert_before ::ActionDispatch::RequestId, LogWeasel::Middleware
    end

    private

    def self.app_name
      ::Rails.application.class.to_s.split("::").first
    end
  end
end