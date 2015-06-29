Given(/^there are (\d+) petitions debated in parliament$/) do |debated_count|
  debated_count.times do |count|
    petition = FactoryGirl.create(:debated_petition, :action => "Petition #{count}")
  end
end

Given(/^there are (\d+) petitions with a government response$/) do |response_count|
  response_count.times do |count|
    petition = FactoryGirl.create(:responded_petition, :action => "Petition #{count}")
  end
end

Then(/^I should not see the actioned petitions section$/) do
  expect(page).to_not have_css(".actioned-petitions")
end

Then(/^I should see there are (.*?) petitions with a government response$/) do |response_count|
  expect(page).to have_css(".actioned-petitions ul li:first-child .count", :text => response_count)
end

Then(/^I should see there are (.*?) petitions debated in parliament$/) do |debated_count|
  expect(page).to have_css(".actioned-petitions ul li:last-child .count", :text => debated_count)
end

Then(/^I should see an empty government response threshold section$/) do
  within(:css, ".threshold-panel[aria-labelledby=response-threshold-heading]") do
    expect(page).to have_no_css("a[href='#{petitions_path(state: :with_response)}']")
  end
end

Then(/^I should see an empty debate threshold section$/) do
  within(:css, ".threshold-panel[aria-labelledby=debate-threshold-heading]") do
    expect(page).to have_no_css("a[href='#{petitions_path(state: :with_debate_outcome)}']")
  end
end

Then(/^I should see the government response threshold section with a count of (\d+)$/) do |response_petitions_count|
  within(:css, ".threshold-panel[aria-labelledby=response-threshold-heading]") do
    link_text = "Petitions with a government response (#{response_petitions_count})"
    expect(page).to have_link(link_text, href: petitions_path(state: :with_response))
  end
end

Then(/^I should see the debate threshold section with a count of (\d+)$/) do |debate_petitions_count|
  within(:css, ".threshold-panel[aria-labelledby=debate-threshold-heading]") do
    link_text = "Petitions debated in parliament (#{debate_petitions_count})"
    expect(page).to have_link(link_text, href: petitions_path(state: :with_debate_outcome))
  end
end
