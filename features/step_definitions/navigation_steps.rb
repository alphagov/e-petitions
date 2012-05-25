When /^I follow "([^\"]*)" in (.*)$/ do |link_text, section_name|
  with_scope(xpath_of_section(section_name)) do
    click_link(link_text)
  end
end

When /^I follow "([^\"]*)" for "([^\"]*)"$/ do |link_text, target|
  xpath_for_parent_of_target = "//*[.='#{target}']/ancestor::tr"
  with_scope(xpath_for_parent_of_target) do
    click_link(link_text)
  end
end