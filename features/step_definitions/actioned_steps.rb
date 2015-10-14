Given(/^there are (\d+) petitions debated in parliament(.+)?$/) do |debated_count, links_command|
  video_url, transcript_url = nil, nil
  if links_command == " with a transcript url"
    video_url = "http://www.example.com/?video=test"
  elsif links_command == " with a video url"
    transcript_url = "http://www.example.com/?video=test"
  elsif links_command == " with both video and transcript urls"
    video_url = "http://www.example.com/?video=test"
    transcript_url = "http://www.example.com/?video=test"
  end
  debated_count.times do |count|
    petition = FactoryGirl.create(:debated_petition, action: "Petition #{count}", video_url: video_url, transcript_url: transcript_url)
  end
end

Given(/^there are (\d+) petitions with a government response$/) do |response_count|
  response_count.times do |count|
    petition = FactoryGirl.create(:responded_petition, :action => "Petition #{count}")
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
