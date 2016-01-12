Given(/^that a petition has been signed (\d+) times from "(.*?)" during the last (\d+) minutes$/) do |count, domain, at|
  travel_to 2.hours.ago do
    @petition = FactoryGirl.create(:open_petition)
  end

  travel_to at.minutes.ago do
    count.times do |i|
      FactoryGirl.create(:pending_signature, email: "user#{i}@#{domain}", petition: @petition)
    end
  end

  Domain.update_rates
end

Given(/^that the domain "(.*?)" has already been whitelisted$/) do |domain|
  FactoryGirl.create(:domain, :allowed, name: domain)
end

Given(/^that the domain "(.*?)" has already been blocked$/) do |domain|
  FactoryGirl.create(:domain, :blocked, name: domain)
end

When(/^I click the allow button for the domain "(.*?)"$/) do |domain|
  within ".//table/tbody/tr/td[1][contains(text(),'#{domain}')]/.." do
    click_button 'Allow'
  end
end

When(/^I click the block button for the domain "(.*?)"$/) do |domain|
  within ".//table/tbody/tr/td[1][contains(text(),'#{domain}')]/.." do
    click_button 'Block'
  end
end

Then(/^I should see the domain name "(.*?)"$/) do |domain|
  expect(page).to have_xpath(".//table/tbody/tr/td[1][contains(text(),'#{domain}')]")
end

Then(/^I should not see the domain name "(.*?)"$/) do |domain|
  expect(page).not_to have_xpath(".//table/tbody/tr/td[1][contains(text(),'#{domain}')]")
end

Then(/^I should see a current rate of (\d+) for the domain "(.*?)"$/) do |value, domain|
  within ".//table/tbody/tr/td[1][contains(text(),'#{domain}')]/.." do
    expect(find("td[2]").text.to_i).to eq(value)
  end
end

Then(/^I should see a maximum rate of (\d+) for the domain "(.*?)"$/) do |value, domain|
  within ".//table/tbody/tr/td[1][contains(text(),'#{domain}')]/.." do
    expect(find("td[3]").text.to_i).to eq(value)
  end
end

Then(/^I should see an allow button for the domain "(.*?)"$/) do |domain|
  within ".//table/tbody/tr/td[1][contains(text(),'#{domain}')]/.." do
    expect(page).to have_xpath("td[4]//input[@type='submit' and @value='Allow']")
  end
end

Then(/^I should not see an allow button for the domain "(.*?)"$/) do |domain|
  within ".//table/tbody/tr/td[1][contains(text(),'#{domain}')]/.." do
    expect(page).not_to have_xpath("td[4]//input[@type='submit' and @value='Allow']")
  end
end

Then(/^I should see a block button for the domain "(.*?)"$/) do |domain|
  within ".//table/tbody/tr/td[1][contains(text(),'#{domain}')]/.." do
    expect(page).to have_xpath("td[4]//input[@type='submit' and @value='Block']")
  end
end

Then(/^I should not see a block button for the domain "(.*?)"$/) do |domain|
  within ".//table/tbody/tr/td[1][contains(text(),'#{domain}')]/.." do
    expect(page).not_to have_xpath("td[4]//input[@type='submit' and @value='Block']")
  end
end
