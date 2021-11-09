Given /^a set of petitions$/ do
  3.times do |x|
    @petition = FactoryBot.create(:open_petition, :with_additional_details, :action => "Petition #{x}")
  end
end

Given(/^a set of (\d+) petitions$/) do |number|
  number.times do |x|
    @petition = FactoryBot.create(:open_petition, :with_additional_details, :action => "Petition #{x}")
  end
end

When(/^I navigate to the next page of petitions$/) do
  click_link "Next"
end

Given(/^an? ?(pending|validated|sponsored|flagged|dormant|open|closed|rejected)? petition "([^"]*)"(?: exists)?$/) do |state, action|
  @petition = FactoryBot.create(:"#{state || 'open'}_petition", action: action)
end

Given(/^a (sponsored|flagged) petition "(.*?)" reached threshold (\d+) days? ago$/) do |state, action, age|
  @petition = FactoryBot.create(:petition, action: action, state: state, moderation_threshold_reached_at: age.days.ago)
end

Given(/^a petition "([^"]*)" with a negative debate outcome$/) do |action|
  @petition = FactoryBot.create(:not_debated_petition, action: action)
end

Given(/^an archived petition "([^"]*)" with a negative debate outcome$/) do |action|
  @petition = FactoryBot.create(:archived_petition, :not_debated, action: action)
end

Given(/^a(n)? ?(archived|pending|validated|sponsored|open)? petition "([^"]*)" with scheduled debate date of "(.*?)"$/) do |_, state, petition_title, scheduled_debate_date|
  step "an #{state} petition \"#{petition_title}\""
  @petition.scheduled_debate_date = scheduled_debate_date.to_date
  @petition.save
end

Given(/^an archived petition "([^"]*)"$/) do |action|
  @parliament = FactoryBot.create(:parliament, :coalition)
  @petition = FactoryBot.create(:archived_petition, :closed, parliament: @parliament, action: action)
end

Given(/^a (stopped|rejected|hidden) archived petition exists with action: "(.*?)"$/) do |state, action|
  @petition = FactoryBot.create(:archived_petition, state.to_sym, action: action)
end

Given(/^the petition "([^"]*)" has (\d+) validated and (\d+) pending signatures$/) do |petition_action, no_validated, no_pending|
  petition = Petition.find_by(action: petition_action)
  (no_validated - 1).times { FactoryBot.create(:validated_signature, petition: petition) }
  no_pending.times { FactoryBot.create(:pending_signature, petition: petition) }
  petition.reload
end

Given(/^(\d+) petitions exist with a signature count of (\d+)$/) do |number, count|
  number.times do
    p = FactoryBot.create(:open_petition)
    p.update_attribute(:signature_count, count)
  end
end

Given(/^a petition "([^"]*)" exists with a signature count of (\d+)$/) do |petition_action, count|
  @petition = FactoryBot.create(:open_petition, action: petition_action)
  @petition.update_attribute(:signature_count, count)
end

Given(/^an open petition "(.*?)" with response "(.*?)" and response summary "(.*?)"$/) do |petition_action, details, summary|
  @petition = FactoryBot.create(:responded_petition, action: petition_action, response_details: details, response_summary: summary)
end

Given(/^a ?(open|closed)? petition "([^"]*)" exists and has received a government response (\d+) days ago$/) do |state, petition_action, parliament_response_days_ago |
  petition_attributes = {
    action: petition_action,
    closed_at: state == 'closed' ? 1.day.ago : 6.months.from_now,
    response_summary: 'Response Summary',
    response_details: 'Government Response',
    government_response_at: parliament_response_days_ago.to_i.days.ago
  }
  FactoryBot.create(:responded_petition, petition_attributes)
end

Given(/^a petition "(.*?)" exists and hasn't passed the threshold for a ?(response|debate)?$/) do |action, response_or_debate|
  FactoryBot.create(:open_petition, action: action)
end

Given(/^a petition "(.*?)" exists and passed the threshold for a response less than a day ago$/) do |action|
  FactoryBot.create(:open_petition, action: action, response_threshold_reached_at: 2.hours.ago)
end

Given(/^a petition "(.*?)" exists and passed the threshold for a response (\d+) days? ago$/) do |action, amount|
  FactoryBot.create(:open_petition, action: action, response_threshold_reached_at: amount.days.ago)
end

Given(/^a petition "(.*?)" passed the threshold for a debate less than a day ago and has no debate date set$/) do |action|
  petition = FactoryBot.create(:awaiting_debate_petition, action: action, debate_threshold_reached_at: 2.hours.ago)
  petition.debate_outcome = nil
end

Given(/^a petition "(.*?)" passed the threshold for a debate (\d+) days? ago and has no debate date set$/) do |action, amount|
  petition = FactoryBot.create(:awaiting_debate_petition, action: action, debate_threshold_reached_at: amount.days.ago)
  petition.debate_outcome = nil
end

Given(/^a petition "(.*?)" passed the threshold for a debate (\d+) days? ago and has a debate in (\d+) days$/) do |action, threshold, debate|
  petition = FactoryBot.create(:awaiting_debate_petition, action: action, debate_threshold_reached_at: threshold.days.ago, scheduled_debate_date: debate.days.from_now)
  petition.debate_outcome = nil
end

Given(/^I have created a petition$/) do
  @petition = FactoryBot.create(:open_petition)
  reset_mailer
end

Given(/^the petition "([^"]*)" has (\d+) validated signatures$/) do |petition_action, no_validated|
  petition = Petition.find_by(action: petition_action)
  (no_validated - 1).times { FactoryBot.create(:validated_signature, petition: petition) }
  petition.reload
  @petition.reload if @petition
end

And(/^the petition "([^"]*)" has reached maximum amount of sponsors$/) do |petition_action|
  petition = Petition.find_by(action: petition_action)
  Site.maximum_number_of_sponsors.times { petition.sponsors.build(FactoryBot.attributes_for(:sponsor)) }
end

And(/^the petition "([^"]*)" has (\d+) pending sponsors$/) do |petition_action, sponsors|
  petition = Petition.find_by(action: petition_action)
  sponsors.times { petition.sponsors.build(FactoryBot.attributes_for(:sponsor)) }
end

Given(/^a petition "([^"]*)" has been closed$/) do |petition_action|
  @petition = FactoryBot.create(:closed_petition, :action => petition_action)
end

Given(/^a petition "([^"]*)" has been closed early because of parliament dissolving$/) do |petition_action|
  open_at = 3.months.ago
  closed_at = 1.month.ago

  Parliament.instance.update! dissolution_at: closed_at,
    dissolution_heading: "Parliament is dissolving",
    dissolution_message: "This means all petitions will close in 2 weeks",
    dissolved_heading: "Parliament has been dissolved",
    dissolved_message: "All petitions have been closed",
    dissolution_faq_url: "https://parliament.example.com/parliament-is-closing",
    show_dissolution_notification: true,
    government_response_heading: "Government will respond",
    government_response_description: "Government responds to all petitions that get more than %{count} signatures",
    government_response_status: "Waiting for a new Petitions Committee after the General Election",
    parliamentary_debate_heading: "This petition will be considered for debate",
    parliamentary_debate_description: "All petitions that have more than %{count} signatures will be considered for debate in the new Parliament",
    parliamentary_debate_status: "Waiting for a new Petitions Committee after the General Election"

  @petition = FactoryBot.create(:closed_petition, action: petition_action, open_at: open_at, closed_at: closed_at)
end

Given(/^the petition "([^"]*)" has been closed early because of parliament dissolving$/) do |petition_action|
  open_at = 3.months.ago
  closed_at = 1.month.ago

  Parliament.instance.update! dissolution_at: closed_at,
    dissolution_heading: "Parliament is dissolving",
    dissolution_message: "This means all petitions will close in 2 weeks",
    dissolved_heading: "Parliament has been dissolved",
    dissolved_message: "All petitions have been closed",
    dissolution_faq_url: "https://parliament.example.com/parliament-is-closing",
    show_dissolution_notification: true,
    government_response_heading: "Government will respond",
    government_response_description: "Government responds to all petitions that get more than %{count} signatures",
    government_response_status: "Waiting for a new Petitions Committee after the General Election",
    parliamentary_debate_heading: "This petition will be considered for debate",
    parliamentary_debate_description: "All petitions that have more than %{count} signatures will be considered for debate in the new Parliament",
    parliamentary_debate_status: "Waiting for a new Petitions Committee after the General Election"

  @petition = Petition.find_by!(action: petition_action)
  @petition.update(state: "closed", open_at: open_at, closed_at: closed_at)
end

Given(/^the petition has closed$/) do
  @petition.close!(@petition.deadline)
end

Given(/^the petition has closed some time ago$/) do
  @petition.close_early!(2.days.ago)
end

Given(/^a petition "([^"]*)" has been rejected( with the reason "([^"]*)")?$/) do |petition_action, reason_or_not, reason|
  reason_text = reason.nil? ? "It doesn't make any sense" : reason
  @petition = FactoryBot.create(:rejected_petition,
    :action => petition_action,
    :rejection_code => "irrelevant",
    :rejection_details => reason_text)
end

Given(/^an archived petition "([^"]*)" has been rejected with the reason "([^"]*)"$/) do |action, rejection_details|
  @petition = FactoryBot.create(:archived_petition, :rejected, action: action, rejection_details: rejection_details)
end

When(/^I view the petition$/) do
  if @petition.is_a?(Archived::Petition)
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
  fill_in "q", :with => "rioters benefits"
  click_button("Continue")
end

When(/^I choose to create a petition anyway$/) do
  click_link_or_button "My petition is different"
end

Then(/^I should see all petitions$/) do
  expect(page).to have_css("ol li", :count => 3)
end

Then(/^I should see the petition details$/) do
  expect(page).to have_content(@petition.action)
  expect(page).to have_content(@petition.background) if @petition.background?

  if @petition.additional_details?
    click_details "More details"
    expect(page).to have_content(@petition.additional_details)
  end
end

Then(/^I should see the vote count, closed and open dates$/) do
  @petition.reload
  expect(page).to have_css("p.signature-count-number", :text => "#{@petition.signature_count} #{'signature'.pluralize(@petition.signature_count)}")

  if @petition.is_a?(Archived::Petition)
    expect(page).to have_css("ul.petition-meta", :text => "Date closed " + @petition.closed_at.strftime("%e %B %Y").squish)
  else
    expect(page).to have_css("li.meta-deadline", :text => "Deadline " + @petition.deadline.strftime("%e %B %Y").squish)
    expect(page).to have_css("li.meta-created-by", :text => "Created by " + @petition.creator.name)
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
  expect(page).not_to have_css("li.meta-created-by", :text => "Created by " + @petition.creator.name)
end

Then(/^I should see the reason for rejection$/) do
  @petition.reload
  expect(page).to have_content(@petition.rejection.details)
end

Then(/^I should be asked to search for a new petition$/) do
  expect(page).to have_content("What do you want us to do?")
  expect(page).to have_css("form textarea[name=q]")
end

Then(/^I should see a list of (\d+) petitions$/) do |petition_count|
  expect(page).to have_css("tbody tr", :count => petition_count)
end

Then(/^I should see my search query already filled in as the action of the petition$/) do
  expect(page).to have_field("What do you want us to do?", text: "rioters benefits")
end

Then(/^I can click on a link to return to the petition$/) do
  expect(page).to have_css("a[href*='/petitions/#{@petition.id}']")
end

Then(/^I should receive an email telling me how to get an MP on board$/) do
  expect(unread_emails_for(@petition.creator.email).size).to eq 1
  open_email(@petition.creator.email)
  expect(current_email.default_part_body.to_s).to include("MP")
end

When(/^I am allowed to make the petition action too long$/) do
  # NOTE: we do this to remove the maxlength attribtue on the petition
  # action input because any modern browser/driver will not let us enter
  # values longer than maxlength and so we can't test our JS validation
  page.execute_script "document.getElementById('petition_creator_action').removeAttribute('maxlength');"
end

When(/^I am allowed to make the creator name too long$/) do
  # NOTE: we do this to remove the maxlength attribtue on the petition
  # name input because any modern browser/driver will not let us enter
  # values longer than maxlength and so we can't test our JS validation
  page.execute_script "document.getElementById('petition_creator_name').removeAttribute('maxlength');"
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
    And I fill in "Tell us more about what you want the Government or Parliament to do" with "Give half of Wimbledon rock to wombats!"
    And I fill in "Tell us more about why you want the Government or Parliament to do it" with "The racial tensions between the wombles and the wombats are heating up. Racial attacks are a regular occurrence and the death count is already in 5 figures. The only resolution to this crisis is to give half of Wimbledon common to the Wombats and to recognise them as their own independent state."
  )
end

Then(/^I should see my constituency "([^"]*)"/) do |constituency|
  expect(page).to have_text(constituency)
end

Then(/^I should see my MP/) do
  expect(page).to have_text("Emily Thornberry MP")
end

Then(/^I can click on a link to visit my MP$/) do
  expect(page).to have_css("a[href*='https://members.parliament.uk/member/1536/contact']")
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
  expect(@sponsor_petition.creator.state).to eq Signature::VALIDATED_STATE
end

Then(/^I can share it via (.+)$/) do |service|
  case service
  when 'Email'
    within(:css, '.petition-share') do
      expect(page).to have_link('Email', href: %r[\Amailto:\?body=#{ERB::Util.url_encode(petition_url(@petition))}&subject=Petition%3A%20#{ERB::Util.url_encode(@petition.action)}\z])
    end
  when 'Facebook'
    within(:css, '.petition-share') do
      expect(page).to have_link('Facebook', href: %r[\Ahttps://www\.facebook\.com/sharer/sharer\.php\?ref=responsive&u=#{ERB::Util.url_encode(petition_url(@petition))}\z])
    end
  when 'Twitter'
    within(:css, '.petition-share') do
      expect(page).to have_link('Twitter', href: %r[\Ahttps://twitter\.com/intent/tweet\?text=Petition%3A%20#{ERB::Util.url_encode(@petition.action)}&url=#{ERB::Util.url_encode(petition_url(@petition))}\z])
    end
  when 'Whatsapp'
    within(:css, '.petition-share') do
      expect(page).to have_link('Whatsapp', href: %r[\Awhatsapp://send\?text=Petition%3A%20#{ERB::Util.url_encode(@petition.action + "\n" + petition_url(@petition))}\z])
    end
  else
    raise ArgumentError, "Unknown sharing service: #{service.inspect}"
  end
end

When(/^I expand "([^"]*)"/) do |text|
  page.find("//details/summary[contains(., '#{text}')]").click
end

When(/^I click to see more details$/) do
  click_details "More details"
end

Then(/^I should see the response "([^"]*)"$/) do |response|
  within :xpath, "//details[summary/.='Read the response in full']/div", visible: true do
    expect(page).to have_content(response)
  end
end

Then(/^I should not see the response "([^"]*)"$/) do |response|
  within :xpath, "//details[summary/.='Read the response in full']" do
    expect(page).to have_no_content(response)
  end
end

Given(/^an? (open|closed|rejected) petition "(.*?)" with some (fraudulent)? ?signatures$/) do |state, petition_action, signature_state|
  petition_closed_at = state == 'closed' ? 1.day.ago : nil
  petition_state = state == 'closed' ? 'open' : state
  petition_args = {
    action: petition_action,
    open_at: 3.months.ago,
    closed_at: petition_closed_at
  }
  @petition = FactoryBot.create(:"#{state}_petition", petition_args)
  signature_state ||= "validated"
  5.times { FactoryBot.create(:"#{signature_state}_signature", petition: @petition) }
end

Given(/^the threshold for a parliamentary debate is "(.*?)"$/) do |amount|
  Site.instance.update!(threshold_for_debate: amount)
end

Given(/^there are (\d+) petitions awaiting a government response$/) do |response_count|
  response_count.times do |count|
    petition = FactoryBot.create(:awaiting_petition, :action => "Petition #{count}")
  end
end

Given(/^a petition "(.*?)" exists with a debate outcome$/) do |action|
  @petition = FactoryBot.create(:debated_petition, action: action, debated_on: 1.day.ago)
end

Given(/^a petition "(.*?)" exists with a debate outcome and with response threshold met$/) do |action|
  @petition = FactoryBot.create(:debated_petition, action: action, debated_on: 1.day.ago, overview: 'Everyone was in agreement, this petition must be made law!', response_threshold_reached_at: 30.days.ago)
end

Given(/^a petition "(.*?)" exists awaiting debate date$/) do |action|
  @petition = FactoryBot.create(:awaiting_debate_petition, action: action)
end

Given(/^a petition "(.*?)" exists with government response$/) do |action|
  @petition = FactoryBot.create(:responded_petition, action: action)
end

Given(/^a petition "(.*?)" exists awaiting government response$/) do |action|
  @petition = FactoryBot.create(:awaiting_petition, action: action)
end

Given(/^a petition "(.*?)" exists with notes "([^"]*)"$/) do |action, notes|
  @petition = FactoryBot.create(:open_petition, action: action, admin_notes: notes)
end

Given(/^an? ?(pending|validated|sponsored|flagged|dormant|open)? petition "(.*?)" exists with tags "([^"]*)"$/) do |state, action, tags|
  tags = tags.split(",").map(&:strip)
  state ||= "open"
  tag_ids = tags.map { |tag| Tag.find_or_create_by(name: tag).id }

  @petition = FactoryBot.create(:open_petition, state: state, action: action, tags: tag_ids)
end

Given(/^an? ?(pending|validated|sponsored|flagged|dormant|open)? petition "(.*?)" exists with departments "([^"]*)"$/) do |state, action, depts|
  depts = depts.split(",").map(&:strip)
  state ||= "open"
  dept_ids = depts.map { |dept| Department.find_or_create_by(name: dept).id }

  @petition = FactoryBot.create(:open_petition, state: state, action: action, departments: dept_ids)
end

Given(/^there are (\d+) petitions with a scheduled debate date$/) do |scheduled_debate_petitions_count|
  scheduled_debate_petitions_count.times do |count|
    FactoryBot.create(:open_petition, :scheduled_for_debate, action: "Petition #{count}")
  end
end

Given(/^there are (\d+) petitions with enough signatures to require a debate$/) do |debate_threshold_petitions_count|
  debate_threshold_petitions_count.times do |count|
    FactoryBot.create(:awaiting_debate_petition, action: "Petition #{count}")
  end
end

Given(/^a petition "(.*?)" has other parliamentary business$/) do |petition_action|
  @petition = FactoryBot.create(:open_petition, action: petition_action)
  @email = FactoryBot.create(:petition_email,
    petition: @petition,
    subject: "Committee to discuss #{petition_action}",
    body: "The Petition Committee will discuss #{petition_action} on the #{Date.tomorrow}"
  )
end

Given(/^an archived petition "(.*?)" has other parliamentary business$/) do |petition_action|
  @petition = FactoryBot.create(:archived_petition, action: petition_action)
  @email = FactoryBot.create(:archived_petition_email,
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

Given(/^these archived petitions? exist?:?$/) do |table|
  parliament = FactoryBot.create(:parliament, :coalition)

  table.raw[1..-1].each do |petition|
    attributes = {
      parliament:      parliament,
      action:          petition[0],
      state:           petition[1],
      signature_count: petition[2],
      created_at:      petition[3]
    }

    FactoryBot.create(:archived_petition, attributes)
  end
end

When (/^I search all petitions for "(.*?)"$/) do |search_term|
  within :css, '.search-petitions' do
    fill_in :search, with: search_term
    step %{I press "Search"}
  end
end

Given(/^all the open petitions have been closed$/) do
  Petition.open_state.find_each do |petition|
    petition.close_early!(1.day.ago)
  end
end

Given(/^(\d+) archived petitions exist$/) do |number|
  number.times do
    FactoryBot.create(:archived_petition)
  end
end
