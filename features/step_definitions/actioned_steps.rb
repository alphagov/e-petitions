Given(/^there (?:are|is) (\d+) petitions? debated in parliament(.+)?$/) do |debated_count, links_command|
  video_url, transcript_url, debate_pack_url, public_engagement_url, debate_summary_url = nil, nil, nil, nil, nil

  if links_command == " with a transcript url"
    transcript_url = "https://hansard.parliament.uk/path/to/transcript"
  elsif links_command == " with a video url"
    video_url = "https://www.youtube.com/watch?v=1234abcd"
  elsif links_command == " with both video and transcript urls"
    video_url = "https://www.youtube.com/watch?v=1234abcd"
    transcript_url = "https://hansard.parliament.uk/path/to/transcript"
  elsif links_command == " with a debate pack url"
    debate_pack_url = "https://researchbriefings.parliament.uk/path/to/briefing"
  elsif links_command == " with a public engagement url"
    public_engagement_url = "https://committees.parliament.uk/public-engagement"
  elsif links_command == " with a debate summary url"
    debate_summary_url = "https://ukparliament.shorthandstories.com/about-a-petition"
  elsif links_command == " with all debate outcome urls"
    video_url = "https://www.youtube.com/watch?v=1234abcd"
    transcript_url = "https://hansard.parliament.uk/path/to/transcript"
    debate_pack_url = "https://researchbriefings.parliament.uk/path/to/briefing"
    public_engagement_url = "https://committees.parliament.uk/public-engagement"
    debate_summary_url = "https://ukparliament.shorthandstories.com/about-a-petition"
  end

  debated_count.times do |count|
    FactoryBot.create(:debated_petition, action: "Petition #{count}", video_url: video_url, transcript_url: transcript_url, debate_pack_url: debate_pack_url, public_engagement_url: public_engagement_url, debate_summary_url: debate_summary_url)
  end
end

Given(/^there are (\d+) petitions with a government response$/) do |response_count|
  response_count.times do |count|
    FactoryBot.create(:responded_petition, :action => "Petition #{count}")
  end
end

Then(/^I should not see the actioned petitions totals section$/) do
  expect(page).to_not have_css(".actioned-petitions")
end

Then(/^I should see a total showing (.*?) petitions with a government response$/) do |response_count|
  expect(page).to have_css(".actioned-petitions ul li:first-child .count", :text => response_count)
end

Then(/^I should see a total showing (.*?) petitions debated in parliament$/) do |debated_count|
  expect(page).to have_css(".actioned-petitions ul li:last-child .count", :text => debated_count)
end

Then(/^I should see an empty government response threshold section$/) do
  within(:css, "section[aria-labelledby=response-threshold-heading]") do
    expect(page).to have_no_css("a[href='#{petitions_path(state: :with_response)}']")
    expect(page).to have_content("The government hasn’t responded to any petitions yet")
  end
end

Then(/^I should see an empty debate threshold section$/) do
  within(:css, "section[aria-labelledby=debate-threshold-heading]") do
    expect(page).to have_no_css("a[href='#{petitions_path(state: :with_debate_outcome)}']")
    expect(page).to have_content("Parliament hasn’t debated any petitions yet")
  end
end

Then(/^I should see (\d+) petitions counted in the response threshold section$/) do |count|
  within(:css, "section[aria-labelledby=response-threshold-heading]") do
    link_text = "See all petitions with a government response (#{count})"
    expect(page).to have_link(link_text, href: petitions_path(state: :with_response))
  end
end

Then(/^I should see (\d+) petitions listed in the response threshold section$/) do |count|
  within(:css, "section[aria-labelledby=response-threshold-heading] .threshold-petitions") do
    expect(page).to have_css(".petition-item", :count => count)
  end
end

Then(/^I should see (\d+) petitions counted in the debate threshold section$/) do |count|
  within(:css, "section[aria-labelledby=debate-threshold-heading]") do
    link_text = "See all petitions debated in parliament (#{count})"
    expect(page).to have_link(link_text, href: petitions_path(state: :debated))
  end
end

Then(/^I should see (\d+) petitions listed in the debate threshold section$/) do |count|
  within(:css, "section[aria-labelledby=debate-threshold-heading] .threshold-petitions") do
    expect(page).to have_css(".petition-item", :count => count)
  end
end

Then (/^I should see (\d+) debated petition video links$/) do |count|
  within(:css, "section[aria-labelledby=debate-threshold-heading]") do
    expect(page).to have_content("Watch the debate", count: count)
  end
end

Then (/^I should see (\d+) debated petition transcript links$/) do |count|
  within(:css, "section[aria-labelledby=debate-threshold-heading]") do
    expect(page).to have_content("Read the transcript", count: count)
  end
end

Then (/^I should see (\d+) debated petition debate pack links$/) do |count|
  within(:css, "section[aria-labelledby=debate-threshold-heading]") do
    expect(page).to have_content("Read the research", count: count)
  end
end

Then (/^I should see (\d+) debated petition public engagement links$/) do |count|
  within(:css, "section[aria-labelledby=debate-threshold-heading]") do
    expect(page).to have_content("Read what the public said", count: count)
  end
end

Then (/^I should see (\d+) debated petition debate summary links$/) do |count|
  within(:css, "section[aria-labelledby=debate-threshold-heading]") do
    expect(page).to have_content("Read a summary of the debate", count: count)
  end
end
