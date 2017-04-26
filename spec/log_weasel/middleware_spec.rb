require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'stitch_fix/log_weasel'


describe StitchFix::LogWeasel::Middleware do
  let(:app) { double(:call) }

  before do
    expect(app).to receive(:call).with(env)

    StitchFix::LogWeasel.configure do |config|
      config.key = "KEY"
    end
  end

  describe ".call" do
    context "given an env" do
      context "when an HTTP_X_REQUEST_ID header is present" do
        let(:env) { {"HTTP_X_REQUEST_ID" => "1234"} }

        it "sets LogWeasel::Transation.id to the X-Request-Id value" do
          expect(StitchFix::LogWeasel::Transaction).to receive(:id=).with("1234")
          StitchFix::LogWeasel::Middleware.new(app).call(env)
        end
      end

      context "when an HTTP_X_REQUEST_ID header is NOT present" do
        let(:env) { {} }

        before do
          allow(StitchFix::LogWeasel::Transaction).to receive(:id).and_return("1234")
        end

        it "creates a new LogWeasel::Transation.id" do
          expect(StitchFix::LogWeasel::Transaction).to receive(:create).with("#{StitchFix::LogWeasel.config.key}-WEB")
          StitchFix::LogWeasel::Middleware.new(app).call(env)
        end

        it "adds a HTTP_X_REQUEST_ID header" do
          expect(StitchFix::LogWeasel::Transaction).to receive(:create).with("#{StitchFix::LogWeasel.config.key}-WEB")
          expect(env).to receive(:[]=).with("HTTP_X_REQUEST_ID", "1234")
          StitchFix::LogWeasel::Middleware.new(app).call(env)
        end
      end

      context "ensure block" do
        let(:env) { {} }

        it "destroys the current LogWeasel::Transaction.id" do
          expect(StitchFix::LogWeasel::Transaction).to receive(:destroy)
          StitchFix::LogWeasel::Middleware.new(app).call(env)
        end
      end
    end
  end
end