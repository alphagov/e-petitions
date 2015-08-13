require 'csv'

class PetitionsCSVPresenter
  attr_reader :petitions, :presenter_class

  def initialize(petitions, presenter_class: PetitionCSVPresenter)
    @petitions, @presenter_class = petitions, presenter_class
  end

  def render
    Enumerator.new do |stream|
      stream << CSV::Row.new(presenter_class.fields, presenter_class.fields, true).to_s

      petitions.in_batches do |petition|
        stream << presenter_class.new(petition).to_csv
      end
    end
  end
end
