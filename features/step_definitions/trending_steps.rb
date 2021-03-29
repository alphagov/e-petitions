Given /^there has been activity on a number of petitions in the last day$/ do
  (1..10).each do |count|
    petition = FactoryBot.create(:open_petition, action: "Petition #{count}")
    count.times { FactoryBot.create(:validated_signature, petition: petition, validated_at: 2.hours.ago) }
  end
end

Then /^I should see the most popular petitions listed on the front page$/ do
  expect(page).to have_css(".trending .petition-item", :count => 3)
end

Then /^I should not see the trending petitions section$/ do
  expect(page).to_not have_css('.trending')
end
