When /^I search for "([^"]*)"? with "([^"]*)"$/ do |facet, term|
  step "I go to the petitions page"
  step "I follow \"#{facet}\""
  step "I fill in \"#{term}\" as my search term"
  step "I press \"Search\""
end

Then /^I should not be able to search via free text$/ do
  expect(page).to have_no_css("form[action=search]")
end

Then /^I should see an? "([^"]*)" petition count of (\d+)$/ do |state, count|
  expect(page).to have_css(%{#other-search-lists a:contains("#{state.capitalize}")}, :text => count.to_s)
end

When(/^I fill in "(.*?)" as my search term$/) do |search_term|
  fill_in :search, with: search_term
end

Then(/^I should see my search term "(.*?)" filled in the search field$/) do |search_term|
  expect(page).to have_field('q', with: search_term)
end
