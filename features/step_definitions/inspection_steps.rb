Then(/^I should see a heading called "(.*?)"$/) do |title|
  expect(page).to have_css('h1', text: "#{title}")
end

Then /^I should (not |)see "([^\"]*)" in the ((?!email\b).*)$/ do |see_or_not, text, section_name|
  if section_name == 'browser page title'
    if see_or_not.blank?
      expect(page).to have_title(text.to_s)
    else
      expect(page).to have_no_title(text.to_s)
    end
  else
    within_section(section_name) do
      if see_or_not.blank?
        expect(page).to have_content(text.to_s)
      else
        expect(page).to have_no_content(text.to_s)
      end
    end
  end
end

### Fields...

Then /^I should see an? "([^\"]*)" (\S+) field$/ do |name, type|
  expect(page).to have_field(name, type: type)
end

Then /^I should not see an? "([^\"]*)" (\S+) field$/ do |name, type|
  expect(page).not_to have_field(name, type: type)
end

### Tables...

Then(/^I should see the following search results:$/) do |values_table|
  values_table.raw.each_with_index do |row, idx|
    expect(page).to have_selector(:css, ".petition-item:nth-of-type(#{idx+1}) h2", text: row[0]);

    if row[1].present?
      expect(page).to have_selector(:css, ".petition-item:nth-of-type(#{idx+1}) p", text: row[1]);
    end
  end
end

Then(/^I should see the following ordered list of petitions:$/) do |table|
  actual_petitions = page.all(:css, '.petition-item a').map(&:text)
  expected_petitions = table.raw.flatten
  expect(actual_petitions).to eq(expected_petitions)
end

Then(/^I should see the following list of petitions:$/) do |table|
  expected_petitions = table.raw.flatten
  expect(page).to have_selector(:css, '.petition-list tbody tr', count: expected_petitions.size)

  expected_petitions.each.with_index do |expected_petition, idx|
    expect(page).to have_selector(:css, ".petition-list tbody tr:nth-child(#{idx+1}) .action", text: expected_petition)
  end
end

Then /^I should see the following list of archived petitions:$/ do |table|
  table.raw.each do |row|
    row.each do |column|
      expect(page).to have_content(column)
    end
  end
end

Then /^I should see (\d+) petitions?$/ do |number|
  expect(page).to have_xpath( "//div[count(div[@class='petition-item'])=#{number.to_i}]" )
end

### Links

Then /^I should (not |)see a link called "([^\"]*)" linking to "([^\"]*)"$/ do |see_or_not, link_text, link_target|
  xpath = "//a[@href=\"#{link_target}\"][. = \"#{link_text}\"]"
  if see_or_not.blank?
    expect(page).to have_xpath(xpath)
  else
    expect(page).to_not have_xpath(xpath)
  end
end
