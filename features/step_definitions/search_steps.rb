When('I search for {string}') do |facet|
  click_link facet
end

When(/^I browse to see only "([^"]*)" petitions$/) do |facet|
  if facet.in?(%w[Open Closed Rejected])
    facet += " petitions"
  end

  step "I go to the petitions page"
  step "I search for #{facet.inspect}"
end

When(/^I browse to see only "([^"]*)" archived petitions$/) do |facet|
  if facet.in?(%w[Closed Rejected])
    facet += " petitions"
  end

  step "I go to the archived petitions page"
  step "I search for #{facet.inspect}"
end

When(/^I search for "([^"]*)" with "([^"]*)"$/) do |facet, term|
  step %{I browse to see only "#{facet}" petitions}
  step %{I fill in "#{term}" as my search term}
  step %{I press "Search"}

  expect(page).to have_selector(:css, "h1", text: /petitions/i)
end

Then(/^I should( not)? see an? "([^"]*)" petition count of (\d+)$/) do |see_or_not, state, count|
  have_petition_count_for_state = have_css(%{#list-navigation a:contains("#{state.capitalize}")}, :text => count.to_s)
  if see_or_not.blank?
    expect(page).to have_petition_count_for_state
  else
    expect(page).not_to have_petition_count_for_state
  end
end

When(/^I fill in "(.*?)" as my search term$/) do |search_term|
  fill_in :search, with: search_term
end

Then(/^I should see my search term "(.*?)" filled in the search field$/) do |search_term|
  expect(page).to have_field('Search', with: search_term)
end

Then(/^I should see the following similar petitions:$/) do |table|
  table.raw.each_with_index do |row, index|
    within :xpath, "(.//*[contains(@class, 'petition-item-existing')])[#{index + 1}]" do
      row.each do |column|
        expect(page).to have_content(column)
      end
    end
  end
end
