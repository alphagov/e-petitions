Then /^I should see an error$/ do
  expect(page).to have_css(".error-message", :text => /.+/)
end
