Given /^there has been activity on a number of petitions in the last hour$/ do
  Department.all.each do |department|
    (1..10).each do |count|
      petition = FactoryGirl.create(:open_petition, :department => department, :title => "#{department.name} Petition ##{count}")
      count.times { FactoryGirl.create(:validated_signature, :petition => petition) }
    end
  end
end

Given /^the trending petitions cache has been updated$/ do
  TrendingPetition.update_homepage_trends
end

Then /^I should see the most popular petitions listed on the front page$/ do
  expect(page).to have_css("#trending_cta_block .petition", :count => 12)
  expect(page).to have_content("Cabinet Office Petition #10")
  expect(page).to have_content("Cabinet Office Petition #9")
  expect(page).to have_content("Cabinet Office Petition #8")
  expect(page).to have_content("Treasury Petition #10")
  expect(page).to have_content("Treasury Petition #9")
  expect(page).to have_content("Treasury Petition #8")
end

Then /^I should not see the trending petitions section$/ do
  expect(page).to_not have_css('#trending_cta_block')
end

Then /^there should be addition petitions hidden and a link to display them$/ do
  expect(page).to have_css('#see_more_trending_petitions')
  expect(page).to have_css('#additional_trending_petitions_block .petition', :count => 6)
end
