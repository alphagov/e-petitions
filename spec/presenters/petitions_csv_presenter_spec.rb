require 'rails_helper'
require 'puma/cli'

RSpec.describe PetitionsCSVPresenter do
  class DummyPresenterClass
    def self.fields
      [:id, :name]
    end

    def initialize(petition)
      @petition = petition
    end

    def to_csv
      self.class.fields.map {|f| @petition[f] }.join(",") + "\n"
    end
  end

  # Use an array that quacks like the expected Browseable::Search instance
  class BatchifiedArray < Array
    alias :in_batches :each
  end

  subject { described_class.new(BatchifiedArray.new([{id: 321, name: "Slim Jim"}]), presenter_class: DummyPresenterClass) }

  describe "#initialize" do
    it "initializes the presenter with default" do
      presenter = described_class.new([1,2,3])
      expect(presenter.petitions).to eq([1,2,3])
      expect(presenter.presenter_class).to eq(PetitionCSVPresenter)
    end

    it "initializes the presenter with custom options" do
      presenter = described_class.new([1,2,3], presenter_class: DummyPresenterClass)
      expect(presenter.petitions).to eq([1,2,3])
      expect(presenter.presenter_class).to eq(DummyPresenterClass)
    end
  end

  describe "#render" do
    let(:enumerator) { subject.render }

    it "returns an enumerator" do
      expect(enumerator).to be_an Enumerator
    end

    it "renders the header and petition fields" do
      expect(enumerator.next).to eq("id,name\n")
      expect(enumerator.next).to eq("321,Slim Jim\n")

      expect {
        enumerator.next
      }.to raise_error(StopIteration)
    end

    context "when the user closes the connection" do
      before do
        allow_any_instance_of(DummyPresenterClass).to receive(:to_csv).and_raise(Puma::ConnectionError)
      end

      it "doesn't raise an error" do
        expect(enumerator.next).to eq("id,name\n")

        expect {
          enumerator.next
        }.to raise_error(StopIteration)
      end
    end
  end
end
