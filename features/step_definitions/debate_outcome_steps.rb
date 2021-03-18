Given(/^a petition "(.*?)" has been debated (\d+) days ago?$/) do |petition_action, debated_days_ago|
  @petition = FactoryBot.create(:debated_petition,
    action: petition_action,
    debated_on: debated_days_ago.days.ago.to_date,
    overview: 'Everyone was in agreement, this petition must be made law!',
    transcript_url: 'https://hansard.parliament.uk/path/to/transcript',
    video_url: 'https://www.youtube.com?v=1234abcd',
    debate_pack_url: 'https://researchbriefings.parliament.uk/path/to/briefing'
  )
  @petition.update(debate_outcome_at: debated_days_ago.days.ago)
end

Given(/^an archived petition "(.*?)" has been debated (\d+) days ago?$/) do |petition_action, debated_days_ago|
  @petition = FactoryBot.create(:archived_petition, :debated,
    action: petition_action,
    debate_outcome_at: debated_days_ago.days.ago,
    debated_on: debated_days_ago.days.ago.to_date,
    overview: 'Everyone was in agreement, this petition must be made law!',
    transcript_url: 'https://hansard.parliament.uk/path/to/transcript',
    video_url: 'https://www.youtube.com?v=1234abcd',
    debate_pack_url: 'https://researchbriefings.parliament.uk/path/to/briefing'
  )
end

Given(/^a petition "(.*?)" has been debated yesterday$/) do |petition_action|
  @petition = FactoryBot.create(:open_petition,
    action: petition_action,
    scheduled_debate_date: 1.day.ago,
    debate_state: 'debated'
  )
end

Given(/^an archived petition "(.*?)" has been debated yesterday$/) do |petition_action|
  @petition = FactoryBot.create(:archived_petition,
    action: petition_action,
    scheduled_debate_date: 1.day.ago,
    debate_state: 'debated'
  )
end

Then(/^I should see the date of the debate is (\d+) days ago$/) do |debated_days_ago|
  within :css, '.debate-outcome' do
    expect(page).to have_content("This topic was debated on #{debated_days_ago.days.ago.to_date.strftime('%-d %B %Y')}")
  end
end

Then(/^I should see links to the transcript, video and research$/) do
  within :css, '.debate-outcome' do
    expect(page).to have_link('Watch the debate', href: 'https://www.youtube.com?v=1234abcd')
    expect(page).to have_link('Read the transcript', href: 'https://hansard.parliament.uk/path/to/transcript')
    expect(page).to have_link('Read the research', href: 'https://researchbriefings.parliament.uk/path/to/briefing')
  end
end

Then(/^I should see a summary of the debate outcome$/) do
  within :css, '.debate-outcome' do
    expect(page).to have_content('Everyone was in agreement, this petition must be made law!')
  end
end

Then(/^the petition should not have debate details$/) do
  @petition.reload
  expect(@petition.debate_outcome).to be_nil
end

When(/^I fill in the debate outcome details$/) do
  fill_in 'Debated on', with: '18/12/2014'
  fill_in 'Overview', with: 'Lots of people spoke about it, no consensus achieved.'
  fill_in 'Transcript URL', with: 'https://hansard.parliament.uk/path/to/transcript'
  fill_in 'Video URL', with: 'https://www.youtube.com/watch?v=1234abcd'
  fill_in 'Debate Pack URL', with: 'https://researchbriefings.parliament.uk/path/to/briefing'
end

Then(/^the petition should have the debate details I provided$/) do
  @petition.reload
  expect(@petition.debate_outcome).to be_present
  expect(@petition.debate_outcome).to be_persisted
  expect(@petition.debate_outcome.debated_on).to eq '18/12/2014'.to_date
  expect(@petition.debate_outcome.overview).to eq 'Lots of people spoke about it, no consensus achieved.'
  expect(@petition.debate_outcome.transcript_url).to eq 'https://hansard.parliament.uk/path/to/transcript'
  expect(@petition.debate_outcome.video_url).to eq 'https://www.youtube.com/watch?v=1234abcd'
  expect(@petition.debate_outcome.debate_pack_url).to eq 'https://researchbriefings.parliament.uk/path/to/briefing'
end

Then(/^the petition creator should have been emailed about the debate$/) do
  @petition.reload
  steps %Q(
    Then "#{@petition.creator.email}" should receive an email
    When they open the email
    Then they should see "Parliament debated your petition" in the email body
    When they follow "#{petition_url(@petition)}" in the email
    Then I should be on the petition page for "#{@petition.action}"
  )
end

Then(/^all the signatories of the petition should have been emailed about the debate$/) do
  @petition.reload
  @petition.signatures.validated.subscribed.where.not(id: @petition.creator.id).each do |signatory|
    steps %Q(
      Then "#{signatory.email}" should receive an email
      When they open the email
      Then they should see "Parliament debated the petition you signed" in the email body
      When they follow "#{petition_url(@petition)}" in the email
      Then I should be on the petition page for "#{@petition.action}"
    )
  end
end
