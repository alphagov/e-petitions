Then(/^I should see a matching signature count of (\d+)$/) do |count|
  expect(page).to have_selector(:css, ".invalidation-list tbody tr:first td:nth-child(3)", text: count)
end

Then(/^I should see an invalidation status of "(.*?)"$/) do |status|
  expect(page).to have_selector(:css, ".invalidation-list tbody tr:first td:nth-child(2)", text: status)
end

Then(/^I should see a invalidated signature count of (\d+)$/) do |count|
  expect(page).to have_selector(:css, ".invalidation-list tbody tr:first td:nth-child(4)", text: count)
end
