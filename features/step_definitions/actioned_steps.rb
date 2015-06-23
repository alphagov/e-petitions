Given /^There are (\d+) petitions debated in parliament$/ do |debated_count|
  debated_count.times do |count|
    petition = FactoryGirl.create(:debated_petition, :action => "Petition #{count}")
  end
end

Given /^There are (\d+) petitions with a government response$/ do |response_count|
  response_count.times do |count|
    petition = FactoryGirl.create(:responded_petition, :action => "Petition #{count}")
  end
end

Then /^I should not see the actioned petitions section$/ do
  expect(page).to_not have_css(".actioned-petitions")
end

Then /^I should see there are (.*?) petitions with a government response$/ do |response_count|
  expect(page).to have_css(".actioned-petitions ul li:first-child .count", :text => response_count)
end

Then /^I should see there are (.*?) petitions debated in parliament$/ do |debated_count|
  expect(page).to have_css(".actioned-petitions ul li:last-child .count", :text => debated_count)
end
