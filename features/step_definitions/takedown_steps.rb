When /^I take down the petition with a reason code "([^"]*)"$/ do |reason_code|
  select reason_code, :from => :petition_rejection_code
  click_button "Take down"
end

Then /^I should not be able to take down the petition$/ do
  visit edit_internal_response_admin_petition_path(@petition)
  expect(page).to have_no_content("Take this petition down")
end

