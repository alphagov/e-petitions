require 'rails_helper'

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
    it "returns an enumerator" do
      expect(subject.render).to be_a Enumerator
    end

    it "renders a header row as the first enumerator call" do
      expect(subject.render.next).to eq("id,name\n")
    end

    it "renders the fields for each petition after the header" do
      enumerator = subject.render
      enumerator.next
      expect(enumerator.next).to eq("321,Slim Jim\n")
    end
  end
end
