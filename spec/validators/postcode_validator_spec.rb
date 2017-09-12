require 'rails_helper'

RSpec.describe PostcodeValidator do
  subject { model.new(postcode: postcode) }
  let(:errors) { subject.errors[:postcode] }

  before do
    subject.valid?
  end

  context "with the default :message option" do
    let :model do
      Class.new do
        include ActiveModel::Model
        attr_accessor :postcode

        validates :postcode, postcode: true

        class << self
          def name
            "Signature"
          end
        end
      end
    end

    describe "with a valid postcode" do
      let(:postcode) { "SW1A1AA" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    describe "with a BFPO postcode" do
      let(:postcode) { "BFPO1234" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    describe "with the Girobank postcode" do
      let(:postcode) { "GIR0AA" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    describe "with an invalid postcode" do
      let(:postcode) { "SW1A" }

      it "adds an error" do
        expect(errors).to include("Postcode not recognised")
      end
    end
  end

  context "with a custom :message option" do
    let :model do
      Class.new do
        include ActiveModel::Model
        attr_accessor :postcode

        validates :postcode, postcode: { message: "That postcode is not allowed" }

        class << self
          def name
            "Signature"
          end
        end
      end
    end

    describe "with a valid postcode" do
      let(:postcode) { "SW1A1AA" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    describe "with a BFPO postcode" do
      let(:postcode) { "BFPO1234" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    describe "with the Girobank postcode" do
      let(:postcode) { "GIR0AA" }

      it "doesn't add an error" do
        expect(errors).to be_empty
      end
    end

    describe "with an invalid postcode" do
      let(:postcode) { "SW1A" }

      it "adds an error" do
        expect(errors).to include("That postcode is not allowed")
      end
    end
  end
end
