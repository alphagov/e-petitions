Then /^the response to "([^"]*)" should be publicly viewable on the petition page$/ do |petition_title|
  petition = Petition.find_by_title(petition_title)
  visit petition_path(petition)
  page.should have_content(petition.response)
end
