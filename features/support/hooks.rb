Before do
  if Petition.respond_to?(:remove_all_from_index!)
    Petition.remove_all_from_index!
  end
end

Before do
  default_url_options[:protocol] = 'https'
end

After do
  Site.reload
end

Before('@admin') do
  Capybara.app_host = 'https://moderate.petition.parliament.uk'
  Capybara.default_host = 'https://moderate.petition.parliament.uk'
end

Before('~@admin') do
  Capybara.app_host = 'https://petition.parliament.uk'
  Capybara.default_host = 'https://petition.parliament.uk'
end
