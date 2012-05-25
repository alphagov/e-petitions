When /^I browse petitions by department$/ do
  visit home_path
  click_link "View e-petitions by government department"
end

Then /^I should see a list of all the departments$/ do
  Department.all.each do |department|
    page.should have_css("a[href*='#{department_path(department.id)}']")
    page.should have_content(department.name)
  end
end

When /^I view the (open|closed|rejected) petitions for the "([^"]*)"$/ do |petition_state, department_name|
  visit departments_path
  click_link department_name
  click_link petition_state.capitalize
end

Then /^I (should|should not) see the petitions belonging to the "([^"]*)"$/ do |should_or_not, department_name|
  department = Department.find_by_name(department_name)
  department.petitions.each do |petition|
    petition_link = "a[href*='#{petition_path(petition.id)}']"
    if (should_or_not == "should")
      page.should have_css(petition_link)
    else
      page.should_not have_css(petition_link)
    end
  end
end

Then /^I should see the petition "([^"]*)"$/ do |petition_title|
  page.should have_content(petition_title)
end

Then /^I should not see the petition "([^"]*)"$/ do |petition_title|
  page.should_not have_content(petition_title)
end

When /^I press the info button next to the department "([^"]*)"$/ do |department_name|
  within "//*[contains(@class, 'department_list')]//*[.='#{department_name}']/.." do
    click_link 'info'
  end
end
