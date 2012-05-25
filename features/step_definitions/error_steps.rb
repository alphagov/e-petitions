Then /^I should see an error$/ do
  page.should have_css(".errors", :text => /.+/)
end
