Given /^there has been activity on a number of petitions in the last hour$/ do
  (1..10).each do |count|
    petition = FactoryGirl.create(:open_petition, :title => "Petition #{count}")
    count.times { FactoryGirl.create(:validated_signature, :petition => petition) }
  end
end

Then /^I should see the most popular petitions listed on the front page$/ do
  expect(page).to have_css("#trending_cta_block .petition", :count => 3)
end

Then /^I should not see the trending petitions section$/ do
  expect(page).to_not have_css('#trending_cta_block')
end
