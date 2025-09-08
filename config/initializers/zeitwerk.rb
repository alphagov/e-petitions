Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "petitions_csv_presenter" => "PetitionsCSVPresenter",
    "petition_csv_presenter" => "PetitionCSVPresenter",
  )
end

unless Rails.application.config.cache_classes
  Rails.autoloaders.main.tap do |autoloader|
    autoloader.on_unload("Constituency::ApiClient") { Thread.current[:__api_client__] = nil }
    autoloader.on_unload("Holiday") { Thread.current[:__holiday__] = nil }
    autoloader.on_unload("Embedding") { Thread.current[:__embedding__] = nil }
    autoloader.on_unload("Parliament") { Thread.current[:__parliament__] = nil }
    autoloader.on_unload("Site") { Thread.current[:__site__] = nil }
    autoloader.on_unload("Mocks") { Mocks.reset! }
  end
end
