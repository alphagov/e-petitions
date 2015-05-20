Given /^there has been activity on a number of petitions in the last hour$/ do
  (1..10).each do |count|
    petition = FactoryGirl.create(:open_petition, :title => "Petition #{count}")
    count.times { FactoryGirl.create(:validated_signature, :petition => petition) }
  end
end

Given /^the trending petitions cache has been updated$/ do
  TrendingPetition.update_homepage_trends
end

Then /^I should see the most popular petitions listed on the front page$/ do
  expect(page).to have_css("#trending_cta_block .petition", :count => 10)
end

Then /^I should not see the trending petitions section$/ do
  expect(page).to_not have_css('#trending_cta_block')
end

Then /^there should be addition petitions hidden and a link to display them$/ do
  expect(page).to have_css('#see_more_trending_petitions')
  expect(page).to have_css('#additional_trending_petitions_block .petition', :count => 4)
end
