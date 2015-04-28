Then /^I should see an error$/ do
  expect(page).to have_css(".errors", :text => /.+/)
end
