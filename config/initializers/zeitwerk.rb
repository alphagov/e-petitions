Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "petitions_csv_presenter" => "PetitionsCSVPresenter",
    "petition_csv_presenter" => "PetitionCSVPresenter",
  )
end
