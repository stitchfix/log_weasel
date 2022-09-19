require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require "active_support"

describe StitchFix::LogWeasel::Transaction do

  describe ".id" do
    context "if not set" do
      it "is nil" do
        expect(StitchFix::LogWeasel::Transaction.id).to be_nil
      end
    end
  end

  describe ".key" do
    context "no transaction set" do
      it "is nil" do
        expect(StitchFix::LogWeasel::Transaction.key).to be_nil
      end
    end

    context "transaction set with ULID" do
      context "includes a key" do
        let(:key) { "TEST-KEY" }
        before do
          StitchFix::LogWeasel::Transaction.create key
        end

        it "returns the proper key" do
          expect(StitchFix::LogWeasel::Transaction.key).to eq key.downcase
        end
      end

      context "does not include a key" do
        before do
          StitchFix::LogWeasel::Transaction.create
        end

        it "is nil" do
          expect(StitchFix::LogWeasel::Transaction.key).to be_nil
        end
      end
    end

    context "transaction set with UUID" do
      context "includes a key" do
        let(:key) { "TEST-KEY" }
        before do
          StitchFix::LogWeasel::Transaction.id = "00660D68-3BFC-4E44-8DBD-66B0A878686A-#{key}"
        end

        it "returns the proper key" do
          expect(StitchFix::LogWeasel::Transaction.key).to eq key.downcase
        end
      end

      context "does not include a key" do
        before do
          StitchFix::LogWeasel::Transaction.id = "00660D68-3BFC-4E44-8DBD-66B0A878686A"
        end

        it "is nil" do
          expect(StitchFix::LogWeasel::Transaction.key).to be_nil
        end
      end
    end
  end

  describe ".id=" do
    before do
      StitchFix::LogWeasel::Transaction.id = "1234"
    end

    it "sets the id" do
      expect(StitchFix::LogWeasel::Transaction.id).to eq "1234"
    end

  end

  describe ".create" do
    let(:regex) { /(?:[A-Z2-7]{8})*(?:[A-Z2-7]{2}={6}|[A-Z2-7]{4}={4}|[A-Z2-7]{5}={3}|[A-Z2-7]{7}=)?/ }
    it "creates a transaction id with no key prefix" do
      id = StitchFix::LogWeasel::Transaction.create
      expect(id).to match(regex)
      expect(id.size).to eq(26)
    end

    it "creates a transaction id with a key suffix" do
      key = "KEY"
      id = StitchFix::LogWeasel::Transaction.create key
      expect(id).to match(/-KEY/)
      expect(id).to match(regex)
      # adds one here to account for hyphen
      expect(id.size).to eq(26 + 1 + key.size)
    end

  end

  describe ".destroy" do
    before do
      StitchFix::LogWeasel::Transaction.create
    end

    it "removes transaction id" do
      StitchFix::LogWeasel::Transaction.destroy
      expect(StitchFix::LogWeasel::Transaction.id).to be_nil
    end
  end
end
