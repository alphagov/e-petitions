Given /^there is a petition "([^"]*)" that has been assigned between two departments several times$/ do |petition_title|
  cabinet_office = Department.find_by_name('Cabinet Office')
  treasury       = Department.find_by_name('Treasury')
  petition = Factory(:validated_petition, :title => petition_title, :department => treasury)

  DepartmentAssignment.create :petition    => petition,
                              :department  => cabinet_office,
                              :assigned_on => Time.parse("Fri Mar 10 10:15:00 +0000 2012")
  DepartmentAssignment.create :petition    => petition,
                              :department  => treasury,
                              :assigned_on => Time.parse("Fri Mar 14 11:30:00 +0000 2012")
  DepartmentAssignment.create :petition    => petition,
                              :department  => cabinet_office,
                              :assigned_on => Time.parse("Fri Mar 17 12:45:00 +0000 2012")
end

When /^I view the "([^"]*)" admin edit page$/ do |petition_title|
  petition = Petition.find_by_title(petition_title)
  visit edit_admin_petition_path(petition)
end
