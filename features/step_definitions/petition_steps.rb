Given /^a set of petitions$/ do
  3.times do |x|
    @petition = FactoryGirl.create(:open_petition, :with_additional_details, :title => "Petition #{x}")
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

Given /^a(n)? ?(pending|validated|sponsored|open)? petition "([^"]*)" with scheduled debate date of "(.*?)"$/ do |_, state, petition_title, scheduled_debate_date|
  step "an #{state} petition \"#{petition_title}\""
  @petition.scheduled_debate_date = scheduled_debate_date.to_date
  @petition.save
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

Given /^a petition "([^"]*)" exists with a signature count of (\d+)$/ do |title, count|
    p = FactoryGirl.create(:open_petition, title: title)
    p.update_attribute(:signature_count, count)
end

Given(/^an open petition "(.*?)" with response "(.*?)" and response summary "(.*?)"$/) do |title, response, response_summary|
  @petition = FactoryGirl.create(:open_petition, title: title, response: response, response_summary: response_summary)
end

Given /^a ?(open|closed)? petition "([^"]*)" exists and has received a government response (\d+) days ago$/ do |state, title, government_response_days_ago |
  petition_attributes = {
    title: title,
    closed_at: state == 'closed' ? 1.day.ago : 6.months.from_now,
    response_summary: 'Response Summary',
    response: 'Government Response',
    government_response_at: government_response_days_ago.to_i.days.ago
  }
  FactoryGirl.create(:open_petition, petition_attributes)
end

Given /^I have created a petition$/ do
  @petition = FactoryGirl.create(:open_petition)
  reset_mailer
end

Given /^the petition "([^"]*)" has (\d+) validated signatures$/ do |title, no_validated|
  petition = Petition.find_by(title: title)
  (no_validated - 1).times { petition.signatures << FactoryGirl.create(:validated_signature) }
end

And (/^the petition "([^"]*)" has reached maximum amount of sponsors$/) do |title|
  petition = Petition.find_by(title: title)
  Site.maximum_number_of_sponsors.times { petition.sponsors.build(FactoryGirl.attributes_for(:sponsor)) }
end

And (/^the petition "([^"]*)" has (\d+) pending sponsors$/) do |title, sponsors|
  petition = Petition.find_by(title: title)
  sponsors.times { petition.sponsors.build(FactoryGirl.attributes_for(:sponsor)) }
end

Given /^a petition "([^"]*)" has been closed$/ do |petition_title|
  @petition = FactoryGirl.create(:open_petition, :title => petition_title, :closed_at => 1.day.ago)
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

When /^I check for similar petitions$/ do
  fill_in "q", :with => "Rioters should loose benefits"
  click_button("Check for similar petitions")
end

When /^I choose to create a petition anyway$/ do
  click_link_or_button "My petition is different"
end

When /^I change the number viewed per page to (\d+)$/ do |per_page|
  select per_page.to_s, :from => 'per_page'
end

Then /^I should see all petitions$/ do
  expect(page).to have_css("ol li", :count => 3)
end

Then /^I should see the petition details$/ do
  expect(page).to have_content(@petition.title)
  if @petition.is_a?(ArchivedPetition)
    expect(page).to have_content(@petition.description)
  else
    expect(page).to have_content(@petition.additional_details)
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

Then /^I should not see the vote count$/ do
  @petition.reload
  expect(page).to_not have_css("p.signature-count", :text => @petition.signature_count.to_s + " signatures")
end

Then /^I should see submitted date$/ do
  @petition.reload
  expect(page).to have_css("li", :text =>  "Date submitted " + @petition.created_at.strftime("%e %B %Y").squish)
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
  expect(page).to have_content("What action would you like the government to take?")
  expect(page).to have_css("form textarea[name=q]")
end

Then /^I should see a list of existing petitions I can sign$/ do
  expect(page).to have_content(@petition.title)
end

Then /^I should see a list of (\d+) petitions$/ do |petition_count|
  expect(page).to have_css("tbody tr", :count => petition_count)
end

Then /^I should see my search query already filled in as the title of the petition$/ do
  expect(page).to have_field("Action", "#{@petition.title}")
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
    Then I should see "Create a new petition - Petitions" in the browser page title
    And I should be connected to the server via an ssl connection
  )
end

When /^I fill in the petition details/ do
  steps %Q(
    When I fill in "Action" with "The wombats of wimbledon rock."
    And I fill in "Background" with "Give half of Wimbledon rock to wombats!"
    And I fill in "Additional details" with "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."
  )
end

Then /^I should see my constituency "([^"]*)"/ do |constituency|
  expect(page).to have_text(constituency)
end

Then /^I should see my MP/ do
  signature = Signature.find_by(email: "womboidian@wimbledon.com",
                                 postcode: "N11TY",
                                 name: "Womboid Wibbledon",
                                 petition_id: @petition.id)
  expect(page).to have_text(signature.constituency.mp.name)
end

Then /^I can click on a link to visit my MP$/ do
  signature = Signature.find_by(email: "womboidian@wimbledon.com",
                                 postcode: "N11TY",
                                 name: "Womboid Wibbledon",
                                 petition_id: @petition.id)
  expect(page).to have_css("a[href*='#{signature.constituency.mp.url}']")
end

Then /^I should not see the text "([^"]*)"/ do |text|
  expect(page).to_not have_text(text)
end

Then(/^my petition should be validated$/) do
  @sponsor_petition.reload
  expect(@sponsor_petition.state).to eq Petition::VALIDATED_STATE
end

Then(/^the petition creator signature should be validated$/) do
  @sponsor_petition.reload
  expect(@sponsor_petition.creator_signature.state).to eq Signature::VALIDATED_STATE
end

Then(/^I can share it via (.+)$/) do |service|
  case service
  when 'Email'
    within(:css, '.petition-share') do
      expect(page).to have_link('Email', %r[\Amailto:?subject=#{URI.escape(@petition.title)}&body=#{URI.escape(petition_url(@petition))}\z])
    end
  when 'Facebook'
    within(:css, '.petition-share') do
      expect(page).to have_link('Facebook', %r[\Ahttp://www.facebook.com/sharer.php?t=#{URI.escape(title)}&u=#{URI.escape(petition_url(@petition))}\z])
    end
  when 'Twitter'
    within(:css, '.petition-share') do
      expect(page).to have_link('Twitter', %r[\Ahttp://twitter.com/share?text=#{URI.escape(title)}&url=#{URI.escape(petition_url(@petition))}\z])
    end
  when 'Whatsapp'
    within(:css, '.petition-share') do
      expect(page).to have_link('Whatsapp', %r[\Awhatsapp://send?text=#{URI.escape(title + "\n" + petition_url(@petition))}\z])
    end
  else
    raise ArgumentError, "Unknown sharing service: #{service.inspect}"
  end
end

Then /^I expand "([^"]*)"/ do |text|
  page.find("//details/summary[contains(., '#{text}')]").click
end

Given(/^an? (open|closed|rejected) petition "(.*?)" with some signatures$/) do |state, title|
  petition_closed_at = state == 'closed' ? 1.day.ago : 1.day.from_now
  petition_state = state == 'closed' ? 'open' : state
  petition_args = {
    title: title,
    open_at: 3.months.ago,
    closed_at: petition_closed_at,
    state: petition_state
  }
  petition = FactoryGirl.create(:open_petition, petition_args)
  5.times { FactoryGirl.create(:validated_signature, petition: petition) }
  Petition.update_all_signature_counts
end

Given(/^the threshold for a parliamentary debate is "(.*?)"$/) do |amount|
  Site.instance.update!(threshold_for_debate: amount)
end
