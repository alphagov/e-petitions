Then /^the response to "([^"]*)" should be publicly viewable on the petition page$/ do |petition_title|
  petition = Petition.find_by(title: petition_title)
  visit petition_path(petition)
  expect(page).to have_content(petition.response)
end

Then /^the response summary to "([^"]*)" should be publicly viewable on the petition page$/ do |petition_title|
  petition = Petition.find_by(title: petition_title)
  visit petition_path(petition)
  expect(page).to have_content(petition.response_summary)
end
