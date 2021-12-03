require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'sidekiq/testing'

class TestWorker
  include Sidekiq::Worker

  def perform
  end
end

describe StitchFix::LogWeasel::Sidekiq do
  around :each do |example|
    StitchFix::LogWeasel::Transaction.destroy
    example.run
    StitchFix::LogWeasel::Transaction.destroy
  end

  around :each do |example|
    Sidekiq::Testing.fake! do
      example.run
    end
  end

  describe "client middleware" do
    around :each do |example|
      Sidekiq.configure_client do |sidekiq|
        sidekiq.client_middleware do |chain|
          chain.add described_class::ClientMiddleware
        end
      end

      example.run

      Sidekiq.configure_client do |sidekiq|
        sidekiq.client_middleware.clear
      end
    end

    it "sets a log_weasel_id on the job context" do
      Sidekiq::Client.push(
        {
          "class" => "FakeJobClass",
          "queue" => "default",
          "args" => []
        }
      )

      job = Sidekiq::Queues["default"].first
      expect(job).to have_key(described_class::LOG_WEASEL_CONTEXT_KEY)
      expect(job).to match(hash_including(described_class::LOG_WEASEL_CONTEXT_KEY => a_kind_of(String)))
    end
  end

  describe "server middleware" do
    before :each do
      Sidekiq::Testing.server_middleware do |chain|
        chain.add described_class::ServerMiddleware
      end
    end

    it "uses any set log_weasel_id on the job context" do
      job = {
        "class" => TestWorker.name,
        "queue" => "default",
        "args" => [],
        described_class::LOG_WEASEL_CONTEXT_KEY => "blah"
      }
      Sidekiq::Client.push(job)
      TestWorker.perform_one

      expect(StitchFix::LogWeasel::Transaction.id).to eq "blah"
    end

    it "create a log_weasel_id if none is present on the job" do
      TestWorker.perform_async

      expect { TestWorker.drain }.to change { StitchFix::LogWeasel::Transaction.id }.from(nil).to(a_kind_of(String))
    end
  end
end
