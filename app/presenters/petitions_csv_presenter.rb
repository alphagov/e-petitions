require 'csv'

class PetitionsCSVPresenter
  attr_reader :petitions, :presenter_class

  def initialize(petitions, presenter_class: PetitionCSVPresenter)
    @petitions, @presenter_class = petitions, presenter_class
  end

  def render
    CSV.generate do |csv|
      csv << presenter_class.fields

      petitions.each do |petition|
        csv << presenter_class.new(petition).to_csv
      end
    end
  end
  alias :to_s :render
end
