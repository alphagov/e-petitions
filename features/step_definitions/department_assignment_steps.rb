Given /^there is a petition "([^"]*)" that has been assigned between two departments several times$/ do |petition_title|
  cabinet_office = Department.find_by(name: 'Cabinet Office')
  treasury       = Department.find_by(name: 'Treasury')
  petition = FactoryGirl.create(:sponsored_petition, :title => petition_title, :department => treasury)

  assignments = petition.department_assignments
  assignments.create! :department => cabinet_office, :assigned_on => "2012-03-10T10:15:00+00:00"
  assignments.create! :department => treasury,       :assigned_on => "2012-03-14T11:30:00+00:00"
  assignments.create! :department => cabinet_office, :assigned_on => "2012-03-17T12:45:00+00:00"
end

When /^I view the "([^"]*)" admin edit page$/ do |petition_title|
  petition = Petition.find_by(title: petition_title)
  visit edit_admin_petition_path(petition)
end
