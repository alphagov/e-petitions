Then /^I should (not |)see "([^\"]*)" in the ((?!email\b).*)$/ do |see_or_not, text, section_name|
  within_section(section_name) do
    if see_or_not.blank?
      page.should have_content(text.to_s)
    else
      page.should have_no_content(text.to_s)
    end
  end
end

### Fields...

Then /^"([^"]*)" should be selected for "([^"]*)"$/ do |value, field|
  field_labeled(field).element.search(".//option[@selected = 'selected']").inner_html.should =~ /#{value}/
end

Then /^I should see an? "([^\"]*)" (\S+) field$/ do |name, type|
  field = find_field(name)
end

Then /^I should not see an? "([^\"]*)" (\S+) field$/ do |name, type|
  page.should_not have_xpath(XPath::HTML.field(name).to_xpath)
end

Then /^I should see an? "([^\"]*)" select field with the following options:$/ do |name, options|
  expected_options = options.raw.flatten
  field = find_field(name)
  field.should_not be_nil
  found_options = field.all('option').map(&:text)
  found_options.should == expected_options
end

Then /^I should see (\d+) dropdowns in the (.*)$/ do |count, section_name|
  within_section(section_name) do
   page.should have_xpath(".//select", :count => count.to_i)
  end
end

Then /^the "([^\"]*)" select field should have "([^\"]*)" selected$/ do |label, value|
  find_field(label).find('.//option[@selected]').text.should == value
end

Then /^the "([^\"]*)" radio button should be selected$/ do |label|
  find_field(label)['checked'].should be_true
end

Then /^the "([^"]*)" row should display as invalid$/ do |field_label|
  row_node = page.find("//label[contains(., '#{field_label}')]/ancestor::*[contains(@class, 'row')] | //*[contains(@class, 'label')][contains(., '#{field_label}')]/ancestor::*[contains(@class, 'row')]")
  row_node["class"].should include("invalid_row")
end

### Tables...

Then /^I should see the following admin index table:$/ do |values_table|
  actual_table = tableish(xpath_of_section('admin index table') + '//tr', 'th,td')
  values_table.diff!(actual_table)
end

Then /^I should see the following search results table:$/ do |values_table|
  values_table.raw.each do |row|
    row.each do |column|
      page.should have_content(column)
    end
  end
end

Then /^I should see the creation date of the petition$/ do
  page.should have_css("th", :text => "Created")
end

Then /^I should not see the signature count or the closing date$/ do
  page.should have_no_css("th", :text => "Signatures")
  page.should have_no_css("th", :text => "Closing")
end

Then /^the row with the name "([^\"]*)" is not listed$/ do |name|
  page.body.should_not =~ /#{name}/
end

Then /^I should see (\d+) rows? in the admin index table$/ do |number|
  page.should have_xpath( "//table[@class='admin_index' and count(tr)=#{number.to_i + 1}]" )
end

Then /^I should see (\d+) petitions?$/ do |number|
  page.should have_xpath( "//table/tbody[count(tr)=#{number.to_i}]" )
end

Then /^the "([^"]*)" tab should be active$/ do |tab_text|
  page.should have_css("ul.tab_menu li.active a", :text => tab_text)
end

### Links

Then /^I should see a link called "([^\"]*)" linking to "([^\"]*)"$/ do |link_text, link_target|
  xpath = "//a[@href=\"#{link_target}\"][. = \"#{link_text}\"]"
  page.should have_xpath( xpath )
end

Then /^"([^"]*)" should show as "([^"]*)"$/ do |node_text, node_class_name|
  page.should have_xpath("//*[.='#{node_text}'][contains(@class, '#{node_class_name}')]")
end
