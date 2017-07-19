require 'rails_helper'

RSpec.describe ModerationDelay, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_length_of(:subject).is_at_most(100) }

    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(2000) }
  end

  describe "#attributes" do
    subject do
      described_class.new(subject: "Subject", body: "Body")
    end

    it "returns a hash of attributes with string keys" do
      expect(subject.attributes).to eq("subject" => "Subject", "body" => "Body")
    end
  end

  describe "#attributes=" do
    context "with string keys in the hash" do
      let(:attributes) do
        { "subject" => "Subject", "body" => "Body" }
      end

      before do
        subject.attributes = attributes
      end

      it "assigns the :subject attribute" do
        expect(subject.subject).to eq("Subject")
      end

      it "assigns the :body attribute" do
        expect(subject.body).to eq("Body")
      end
    end

    context "with symbol keys in the hash" do
      let(:attributes) do
        { subject: "Subject", body: "Body" }
      end

      before do
        subject.attributes = attributes
      end

      it "assigns the :subject attribute" do
        expect(subject.subject).to eq("Subject")
      end

      it "assigns the :body attribute" do
        expect(subject.body).to eq("Body")
      end
    end

    context "with invalid keys in the hash" do
      let(:attributes) do
        { subject: "Subject", body: "Body", foo: "bar" }
      end

      it "doesn't raise an error" do
        expect {
          subject.attributes = attributes
        }.not_to raise_error
      end
    end
  end
end
