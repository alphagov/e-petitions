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
      self.class.fields.map {|f| @petition[f] }
    end
  end

  subject { described_class.new([{id: 321, name: "Slim Jim"}], presenter_class: DummyPresenterClass) }

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
    it "renders a header row" do
      expect(subject.render.split("\n")[0]).to eq("id,name")
    end

    it "renders the fields for each petition" do
      expect(subject.render.split("\n")[1]).to eq("321,Slim Jim")
    end
  end

  describe "#to_s" do
    it "is an alias to #render" do
      expect(subject.to_s).to eq("id,name\n321,Slim Jim\n")
    end
  end
end
