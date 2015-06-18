Given(/^a petition "(.*?)" has been debated$/) do |petition_title|
  @petition = FactoryGirl.create(:debated_petition,
    title: petition_title,
    debated_on: 6.months.ago.to_date,
    overview: 'Everyone was in agreement, this petition must be made law!',
    transcript_url: 'http://transcripts.parliament.example.com/2.html',
    video_url: 'http://videos.parliament.example.com/2.avi'
  )
end

Then(/^I should see the date of the debate$/) do
  within :css, '.debate-outcome' do
    expect(page).to have_content("This topic was debated on #{6.months.ago.to_date.strftime('%-d %B %Y')}")
  end
end

Then(/^I should see links to transcript and video$/) do
  within :css, '.debate-outcome' do
    expect(page).to have_link('Watch the debate', href: 'http://videos.parliament.example.com/2.avi')
    expect(page).to have_link('Read the transcript', href: 'http://transcripts.parliament.example.com/2.html')
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
  fill_in 'Transcript URL', with: 'http://transcripts.parliament.example.com/1.html'
  fill_in 'Video URL', with: 'http://videos.parliament.example.com/1.mp4'
end

Then(/^the petition should have the debate details I provided$/) do
  @petition.reload
  expect(@petition.debate_outcome).to be_present
  expect(@petition.debate_outcome).to be_persisted
  expect(@petition.debate_outcome.debated_on).to eq '18/12/2014'.to_date
  expect(@petition.debate_outcome.overview).to eq 'Lots of people spoke about it, no consensus achieved.'
  expect(@petition.debate_outcome.transcript_url).to eq 'http://transcripts.parliament.example.com/1.html'
  expect(@petition.debate_outcome.video_url).to eq 'http://videos.parliament.example.com/1.mp4'
end
