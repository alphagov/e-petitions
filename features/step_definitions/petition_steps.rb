Given /^a set of petitions$/ do
  3.times do |x|
    @petition = FactoryGirl.create(:open_petition, :title => "Petition #{x}", :description => "description")
  end
end

Then /^I am taken to a landing page$/ do
  expect(page).to have_content("Thank you")
end

Given /^a(n)? ?(pending|validated|sponsored|open)? petition "([^"]*)"$/ do |a_or_an, state, petition_title|
  petition_args = {
    :title => petition_title,
    :closed_at => 1.day.from_now,
    :state => state || "open"
  }
  @petition = FactoryGirl.create(:open_petition, petition_args)
end

Given(/^an archived petition "([^"]*)"$/) do |title|
  @petition = FactoryGirl.create(:archived_petition, :closed, title: title)
end

Given(/^a rejected archived petition exists with title: "(.*?)"$/) do |title|
  @petition = FactoryGirl.create(:archived_petition, :rejected, title: title)
end

Given /^the petition "([^"]*)" has (\d+) validated and (\d+) pending signatures$/ do |title, no_validated, no_pending|
  petition = Petition.find_by(title: title)
  (no_validated - 1).times { petition.signatures << FactoryGirl.create(:validated_signature) }
  no_pending.times { petition.signatures << FactoryGirl.create(:pending_signature) }
end

Given /^(\d+) petitions exist with a signature count of (\d+)$/ do |number, count|
  number.times do
    p = FactoryGirl.create(:open_petition)
    p.update_attribute(:signature_count, count)
  end
end

Given /^I have created an e-petition$/ do
  @petition = FactoryGirl.create(:open_petition)
  reset_mailer
end

Given /^the petition "([^"]*)" has (\d+) validated signatures$/ do |title, no_validated|
  petition = Petition.find_by(title: title)
  (no_validated - 1).times { petition.signatures << FactoryGirl.create(:validated_signature) }
end

And (/^the petition "([^"]*)" has reached maximum amount of sponsors$/) do |title|
  petition = Petition.find_by(title: title)
  AppConfig.sponsor_count_max.times { petition.sponsors.build(FactoryGirl.attributes_for(:sponsor)) }
end

And (/^the petition "([^"]*)" has (\d+) pending sponsors$/) do |title, sponsors|
  petition = Petition.find_by(title: title)
  sponsors.times { petition.sponsors.build(FactoryGirl.attributes_for(:sponsor)) }
end

Given /^a petition "([^"]*)" has been closed$/ do |petition_title|
  @petition = FactoryGirl.create(:open_petition, :title => petition_title, :closed_at => 1.day.ago)
end

Given /^a libelous petition "([^"]*)" has been rejected$/ do |petition_title|
  @petition = FactoryGirl.create(:petition,
    :title => petition_title,
    :state => Petition::HIDDEN_STATE,
    :rejection_code => "libellous",
    :rejection_text => "You can't say that!")
end

Given /^a petition "([^"]*)" has been rejected( with the reason "([^"]*)")?$/ do |petition_title, reason_or_not, reason|
  reason_text = reason.nil? ? "It doesn't make any sense" : reason
  @petition = FactoryGirl.create(:petition,
    :title => petition_title,
    :state => Petition::REJECTED_STATE,
    :rejection_code => "irrelevant",
    :rejection_text => reason_text)
end

Given(/^an archived petition "([^"]*)" has been rejected with the reason "([^"]*)"$/) do |title, reason_for_rejection|
  @petition = FactoryGirl.create(:archived_petition, :rejected, title: title, reason_for_rejection: reason_for_rejection)
end

When /^I view the petition$/ do
  if @petition.is_a?(ArchivedPetition)
    visit archived_petition_path(@petition)
  else
    visit petition_path(@petition)
  end
end

When(/^I view the petition at the old url$/) do
  visit petition_path(@petition)
end

Then(/^I should be redirected to the archived url$/) do
  expect(current_path).to eq(archived_petition_path(@petition))
end

When /^I view all petitions from the home page$/ do
  visit home_path
  click_link "View all"
end

When /^I check my petition title$/ do
  within(:css, "form#pre_creation_search") do
    fill_in "search", :with => "Rioters should loose benefits"
    click_button("Search")
  end
end

When /^I choose to create a petition anyway$/ do
  click_link_or_button "Create e-petition"
end

When /^I change the number viewed per page to (\d+)$/ do |per_page|
  select per_page.to_s, :from => 'per_page'
end

Then /^I should see all petitions$/ do
  expect(page).to have_content("All e-petitions")
  expect(page).to have_css("tbody tr", :count => 3)
end

Then /^I should see the petition details$/ do
  expect(page).to have_content(@petition.title)
  expect(page).to have_content(@petition.description)

  unless @petition.is_a?(ArchivedPetition)
    expect(page).to have_content(@petition.action)
  end
end

Then /^I should see the vote count, closed and open dates$/ do
  @petition.reload
  expect(page).to have_css("p.signature-count", :text => @petition.signature_count.to_s + " signatures")
  expect(page).to have_css("li.meta-deadline", :text => "Deadline " + @petition.closed_at.strftime("%e %B %Y").squish)

  unless @petition.is_a?(ArchivedPetition)
    expect(page).to have_css("li.meta-created-by", :text => "Created by " + @petition.creator_signature.name)
  end
end

Then /^I should see the reason for rejection$/ do
  @petition.reload

  if @petition.is_a?(ArchivedPetition)
    expect(page).to have_content(@petition.reason_for_rejection)
  else
    expect(page).to have_content(@petition.rejection_text)
  end
end

And /^all petitions have had their signatures counted$/ do
  Petition.update_all_signature_counts
end

Then /^I should be asked to search for a new petition$/ do
  expect(page).to have_css("form#pre_creation_search input#search")
end

Then /^I should see a list of existing petitions I can sign$/ do
  expect(page).to have_content(@petition.title)
end

Then /^I should see a list of (\d+) petitions$/ do |petition_count|
  expect(page).to have_css("tbody tr", :count => petition_count)
end

Then /^I should see my search query already filled in as the title of the petition$/ do
  expect(page).to have_css("input[value='#{@petition.title}']")
end

Then /^I can click on a link to return to the petition$/ do
  expect(page).to have_css("a[href*='/petitions/#{@petition.id}']")
end

Then /^I should receive an email telling me how to get an MP on board$/ do
  expect(unread_emails_for(@petition.creator_signature.email).size).to eq 1
  open_email(@petition.creator_signature.email)
  expect(current_email.default_part_body.to_s).to include("MP")
end

When(/^I am allowed to make the petition title too long$/) do
  # NOTE: we do this to remove the maxlength attribtue on the petition
  # title input because any modern browser/driver will not let us enter
  # values longer than maxlength and so we can't test our JS validation
  page.execute_script "document.getElementById('petition_title').removeAttribute('maxlength');"
end

Then(/^the petition with title: "(.*?)" should have requested an email after "(.*?)"$/) do |title, timestamp|
  petition = Petition.find_by!(title: title)
  expect(petition.email_requested_at).to be >= timestamp.in_time_zone
end

Then(/^the petition with title: "(.*?)" should not have requested an email$/) do |title|
  petition = Petition.find_by!(title: title)
  expect(petition.email_requested_at).to be_nil
end

When /^I start a new petition/ do
  steps %Q(
    Given I am on the new petition page
    Then I should see "Create a new e-petition - e-petitions" in the browser page title
    And I should be connected to the server via an ssl connection
  )
end

When /^I fill in the petition details/ do
  steps %Q(
    When I fill in "Title" with "The wombats of wimbledon rock."
    And I fill in "Action" with "Give half of Wimbledon rock to wombats!"
    And I fill in "Description" with "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."
  )
end

Then /^I should see my constituency "([^"]*)"/ do |constituency|
  expect(page).to have_text(constituency)
end

Then /^I should not see the text "([^"]*)"/ do |text|
  expect(page).to_not have_text(text)
end

Then(/^the e\-petition should be validated$/) do
  @sponsor_petition.reload
  expect(@sponsor_petition.state).to eq Petition::VALIDATED_STATE
end

Then(/^the e\-petition creator signature should be validated$/) do
  @sponsor_petition.reload
  expect(@sponsor_petition.creator_signature.state).to eq Signature::VALIDATED_STATE
end
