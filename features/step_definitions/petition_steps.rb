Given /^a set of petitions$/ do
  3.times do |x|
    @petition = FactoryGirl.create(:open_petition, :with_additional_details, :action => "Petition #{x}")
  end
end

Given(/^a(n)? ?(pending|validated|sponsored|flagged|open)? petition "([^"]*)"$/) do |a_or_an, state, petition_action|
  petition_args = {
    :action => petition_action,
    :closed_at => 1.day.from_now,
    :state => state || "open"
  }
  @petition = FactoryGirl.create(:open_petition, petition_args)
end

Given(/^a petition "([^"]*)" with a negative debate outcome$/) do |action|
  @petition = FactoryGirl.create(:not_debated_petition, action: action)
end


Given(/^a(n)? ?(pending|validated|sponsored|open)? petition "([^"]*)" with scheduled debate date of "(.*?)"$/) do |_, state, petition_title, scheduled_debate_date|
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

Given(/^the petition "([^"]*)" has (\d+) validated and (\d+) pending signatures$/) do |petition_action, no_validated, no_pending|
  petition = Petition.find_by(action: petition_action)
  (no_validated - 1).times { FactoryGirl.create(:validated_signature, petition: petition) }
  no_pending.times { FactoryGirl.create(:pending_signature, petition: petition) }
  petition.reload
end

Given(/^(\d+) petitions exist with a signature count of (\d+)$/) do |number, count|
  number.times do
    p = FactoryGirl.create(:open_petition)
    p.update_attribute(:signature_count, count)
  end
end

Given(/^a petition "([^"]*)" exists with a signature count of (\d+)$/) do |petition_action, count|
  @petition = FactoryGirl.create(:open_petition, action: petition_action)
  @petition.update_attribute(:signature_count, count)
end

Given(/^an open petition "(.*?)" with response "(.*?)" and response summary "(.*?)"$/) do |petition_action, details, summary|
  @petition = FactoryGirl.create(:responded_petition, action: petition_action, response_details: details, response_summary: summary)
end

Given(/^a ?(open|closed)? petition "([^"]*)" exists and has received a government response (\d+) days ago$/) do |state, petition_action, parliament_response_days_ago |
  petition_attributes = {
    action: petition_action,
    closed_at: state == 'closed' ? 1.day.ago : 6.months.from_now,
    response_summary: 'Response Summary',
    response_details: 'Government Response',
    government_response_at: parliament_response_days_ago.to_i.days.ago
  }
  FactoryGirl.create(:responded_petition, petition_attributes)
end

Given(/^a petition "(.*?)" exists and hasn't passed the threshold for a ?(response|debate)?$/) do |action, response_or_debate|
  FactoryGirl.create(:open_petition, action: action)
end

Given(/^a petition "(.*?)" exists and passed the threshold for a response less than a day ago$/) do |action|
  FactoryGirl.create(:open_petition, action: action, response_threshold_reached_at: 2.hours.ago)
end

Given(/^a petition "(.*?)" exists and passed the threshold for a response (\d+) days? ago$/) do |action, amount|
  FactoryGirl.create(:open_petition, action: action, response_threshold_reached_at: amount.days.ago)
end

Given(/^a petition "(.*?)" passed the threshold for a debate less than a day ago and has no debate date set$/) do |action|
  petition = FactoryGirl.create(:awaiting_debate_petition, action: action, debate_threshold_reached_at: 2.hours.ago)
  petition.debate_outcome = nil
end

Given(/^a petition "(.*?)" passed the threshold for a debate (\d+) days? ago and has no debate date set$/) do |action, amount|
  petition = FactoryGirl.create(:awaiting_debate_petition, action: action, debate_threshold_reached_at: amount.days.ago)
  petition.debate_outcome = nil
end

Given(/^a petition "(.*?)" passed the threshold for a debate (\d+) days? ago and has a debate in (\d+) days$/) do |action, threshold, debate|
  petition = FactoryGirl.create(:awaiting_debate_petition, action: action, debate_threshold_reached_at: threshold.days.ago, scheduled_debate_date: debate.days.from_now)
  petition.debate_outcome = nil
end

Given(/^I have created a petition$/) do
  @petition = FactoryGirl.create(:open_petition)
  reset_mailer
end

Given(/^the petition "([^"]*)" has (\d+) validated signatures$/) do |petition_action, no_validated|
  petition = Petition.find_by(action: petition_action)
  (no_validated - 1).times { FactoryGirl.create(:validated_signature, petition: petition) }
  petition.reload
  @petition.reload if @petition
end

And(/^the petition "([^"]*)" has reached maximum amount of sponsors$/) do |petition_action|
  petition = Petition.find_by(action: petition_action)
  Site.maximum_number_of_sponsors.times { petition.sponsors.build(FactoryGirl.attributes_for(:sponsor)) }
end

And(/^the petition "([^"]*)" has (\d+) pending sponsors$/) do |petition_action, sponsors|
  petition = Petition.find_by(action: petition_action)
  sponsors.times { petition.sponsors.build(FactoryGirl.attributes_for(:sponsor)) }
end

Given(/^a petition "([^"]*)" has been closed$/) do |petition_action|
  @petition = FactoryGirl.create(:closed_petition, :action => petition_action)
end

Given(/^a petition "([^"]*)" has been rejected( with the reason "([^"]*)")?$/) do |petition_action, reason_or_not, reason|
  reason_text = reason.nil? ? "It doesn't make any sense" : reason
  @petition = FactoryGirl.create(:rejected_petition,
    :action => petition_action,
    :rejection_code => "irrelevant",
    :rejection_details => reason_text)
end

Given(/^an archived petition "([^"]*)" has been rejected with the reason "([^"]*)"$/) do |title, reason_for_rejection|
  @petition = FactoryGirl.create(:archived_petition, :rejected, title: title, reason_for_rejection: reason_for_rejection)
end

When(/^I view the petition$/) do
  if @petition.is_a?(ArchivedPetition)
    visit archived_petition_url(@petition)
  else
    visit petition_url(@petition)
  end
end

When(/^I view the petition at the old url$/) do
  visit petition_url(@petition)
end

Then(/^I should be redirected to the archived url$/) do
  expect(current_path).to eq(archived_petition_path(@petition))
end

When /^I view all petitions from the home page$/ do
  visit home_url
  click_link "All petitions"
end

When(/^I check for similar petitions$/) do
  fill_in "q", :with => "Rioters should loose benefits"
  click_button("Continue")
end

When(/^I choose to create a petition anyway$/) do
  click_link_or_button "My petition is different"
end

Then(/^I should see all petitions$/) do
  expect(page).to have_css("ol li", :count => 3)
end

Then(/^I should see the petition details$/) do
  if @petition.is_a?(ArchivedPetition)
    expect(page).to have_content(@petition.title)
    expect(page).to have_content(@petition.description)
  else
    expect(page).to have_content(@petition.action)
    expect(page).to have_content(@petition.additional_details)
    expect(page).to have_content(@petition.background)
  end
end

Then(/^I should see the vote count, closed and open dates$/) do
  @petition.reload
  expect(page).to have_css("p.signature-count-number", :text => "#{@petition.signature_count} #{'signature'.pluralize(@petition.signature_count)}")

  if @petition.is_a?(ArchivedPetition)
    expect(page).to have_css("li.meta-deadline", :text => "Deadline " + @petition.closed_at.strftime("%e %B %Y").squish)
  else
    expect(page).to have_css("li.meta-deadline", :text => "Deadline " + @petition.deadline.strftime("%e %B %Y").squish)
    expect(page).to have_css("li.meta-created-by", :text => "Created by " + @petition.creator_signature.name)
  end
end

Then(/^I should not see the vote count$/) do
  @petition.reload
  expect(page).to_not have_css("p.signature-count-number", :text => @petition.signature_count.to_s + " signatures")
end

Then(/^I should see submitted date$/) do
  @petition.reload
  expect(page).to have_css("li", :text =>  "Date submitted " + @petition.created_at.strftime("%e %B %Y").squish)
end

Then(/^I should not see the petition creator$/) do
  expect(page).not_to have_css("li.meta-created-by", :text => "Created by " + @petition.creator_signature.name)
end

Then(/^I should see the reason for rejection$/) do
  @petition.reload

  if @petition.is_a?(ArchivedPetition)
    expect(page).to have_content(@petition.reason_for_rejection)
  else
    expect(page).to have_content(@petition.rejection.details)
  end
end

Then(/^I should be asked to search for a new petition$/) do
  expect(page).to have_content("What do you want us to do?")
  expect(page).to have_css("form textarea[name=q]")
end

Then(/^I should see a list of existing petitions I can sign$/) do
  expect(page).to have_content(@petition.action)
end

Then(/^I should see a list of (\d+) petitions$/) do |petition_count|
  expect(page).to have_css("tbody tr", :count => petition_count)
end

Then(/^I should see my search query already filled in as the action of the petition$/) do
  expect(page).to have_field("What do you want us to do?", "#{@petition.action}")
end

Then(/^I can click on a link to return to the petition$/) do
  expect(page).to have_css("a[href*='/petitions/#{@petition.id}']")
end

Then(/^I should receive an email telling me how to get an MP on board$/) do
  expect(unread_emails_for(@petition.creator_signature.email).size).to eq 1
  open_email(@petition.creator_signature.email)
  expect(current_email.default_part_body.to_s).to include("MP")
end

When(/^I am allowed to make the petition action too long$/) do
  # NOTE: we do this to remove the maxlength attribtue on the petition
  # action input because any modern browser/driver will not let us enter
  # values longer than maxlength and so we can't test our JS validation
  page.execute_script "document.getElementById('petition_action').removeAttribute('maxlength');"
end

Then(/^the petition with action: "(.*?)" should have requested a government response email after "(.*?)"$/) do |petition_action, timestamp|
  petition = Petition.find_by!(action: petition_action)
  email_requested_at = petition.get_email_requested_at_for('government_response')
  expect(email_requested_at).to be_present
  expect(email_requested_at).to be >= timestamp.in_time_zone
end

Then(/^the petition with action: "(.*?)" should not have requested a government response email$/) do |petition_action|
  petition = Petition.find_by!(action: petition_action)
  email_requested_at = petition.get_email_requested_at_for('government_response')
  expect(email_requested_at).to be_nil
end

When(/^I start a new petition/) do
  steps %Q(
    Given I am on the new petition page
    Then I should see "Start a petition - Petitions" in the browser page title
    And I should be connected to the server via an ssl connection
  )
end

When(/^I fill in the petition details/) do
  steps %Q(
    When I fill in "What do you want us to do?" with "The wombats of wimbledon rock."
    And I fill in "Background" with "Give half of Wimbledon rock to wombats!"
    And I fill in "Additional details" with "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."
  )
end

Then(/^I should see my constituency "([^"]*)"/) do |constituency|
  expect(page).to have_text(constituency)
end

Then(/^I should see my MP/) do
  signature = Signature.find_by(email: "womboidian@wimbledon.com",
                                 postcode: "N11TY",
                                 name: "Womboid Wibbledon",
                                 petition_id: @petition.id)
  expect(page).to have_text(signature.constituency.mp_name)
end

Then(/^I can click on a link to visit my MP$/) do
  signature = Signature.find_by(email: "womboidian@wimbledon.com",
                                 postcode: "N11TY",
                                 name: "Womboid Wibbledon",
                                 petition_id: @petition.id)
  expect(page).to have_css("a[href*='#{signature.constituency.mp_url}']")
end

Then(/^I should not see the text "([^"]*)"/) do |text|
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
      expect(page).to have_link('Email', %r[\Amailto:?subject=#{URI.escape(@petition.action)}&body=#{URI.escape(petition_url(@petition))}\z])
    end
  when 'Facebook'
    within(:css, '.petition-share') do
      expect(page).to have_link('Facebook', %r[\Ahttp://www.facebook.com/sharer.php?t=#{URI.escape(@petition.action)}&u=#{URI.escape(petition_url(@petition))}\z])
    end
  when 'Twitter'
    within(:css, '.petition-share') do
      expect(page).to have_link('Twitter', %r[\Ahttp://twitter.com/share?text=#{URI.escape(@petition.action)}&url=#{URI.escape(petition_url(@petition))}\z])
    end
  when 'Whatsapp'
    within(:css, '.petition-share') do
      expect(page).to have_link('Whatsapp', %r[\Awhatsapp://send?text=#{URI.escape(@petition.action + "\n" + petition_url(@petition))}\z])
    end
  else
    raise ArgumentError, "Unknown sharing service: #{service.inspect}"
  end
end

Then(/^I expand "([^"]*)"/) do |text|
  page.find("//details/summary[contains(., '#{text}')]").click
end

Given(/^an? (open|closed|rejected) petition "(.*?)" with some signatures$/) do |state, petition_action|
  petition_closed_at = state == 'closed' ? 1.day.ago : nil
  petition_state = state == 'closed' ? 'open' : state
  petition_args = {
    action: petition_action,
    open_at: 3.months.ago,
    closed_at: petition_closed_at,
    state: petition_state
  }
  @petition = FactoryGirl.create(:open_petition, petition_args)
  5.times { FactoryGirl.create(:validated_signature, petition: @petition) }
end

Given(/^the threshold for a parliamentary debate is "(.*?)"$/) do |amount|
  Site.instance.update!(threshold_for_debate: amount)
end

Given(/^there are (\d+) petitions awaiting a government response$/) do |response_count|
  response_count.times do |count|
    petition = FactoryGirl.create(:awaiting_petition, :action => "Petition #{count}")
  end
end

Given(/^a petition "(.*?)" exists with a debate outcome$/) do |action|
  @petition = FactoryGirl.create(:debated_petition, action: action, debated_on: 1.day.ago)
end

Given(/^a petition "(.*?)" exists awaiting debate date$/) do |action|
  @petition = FactoryGirl.create(:awaiting_debate_petition, action: action)
end

Given(/^a petition "(.*?)" exists with government response$/) do |action|
  @petition = FactoryGirl.create(:responded_petition, action: action)
end

Given(/^a petition "(.*?)" exists awaiting government response$/) do |action|
  @petition = FactoryGirl.create(:awaiting_petition, action: action)
end

Given(/^a petition "(.*?)" exists with notes "([^"]*)"$/) do |action, notes|
  @petition = FactoryGirl.create(:open_petition, action: action, admin_notes: notes)
end

Given(/^there are (\d+) petitions with a scheduled debate date$/) do |scheduled_debate_petitions_count|
  scheduled_debate_petitions_count.times do |count|
    FactoryGirl.create(:open_petition, :scheduled_for_debate, action: "Petition #{count}")
  end
end

Given(/^there are (\d+) petitions with enough signatures to require a debate$/) do |debate_threshold_petitions_count|
  debate_threshold_petitions_count.times do |count|
    FactoryGirl.create(:awaiting_debate_petition, action: "Petition #{count}")
  end
end

Given(/^a petition "(.*?)" has other parliamentary business$/) do |petition_action|
  @petition = FactoryGirl.create(:open_petition, action: petition_action)
  @email = FactoryGirl.create(:petition_email,
    petition: @petition,
    subject: "Committee to discuss #{petition_action}",
    body: "The Petition Committee will discuss #{petition_action} on the #{Date.tomorrow}"
  )
end

Then(/^I should see the other business items$/) do
  steps %Q(
    Then I should see "Other parliamentary business"
    And I should see "Committee to discuss #{@petition.action}"
    And I should see "The Petition Committee will discuss #{@petition.action} on the #{Date.tomorrow}"
  )
end
