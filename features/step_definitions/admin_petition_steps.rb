Then(/^I should see the creator’s name in the petition details$/) do
  within :css, ".petition-meta .creator-name" do
    expect(page).to have_text(@petition.creator.name)
  end
end

Then(/^I should see the creator’s constituency in the petition details$/) do
  within :css, ".petition-meta .creator-constituency" do
    expect(page).to have_text(@petition.creator.constituency.name)
  end
end

Then(/^I should see the creator’s region in the petition details$/) do
  within :css, ".petition-meta .creator-constituency" do
    expect(page).to have_text(@petition.creator.constituency.region.name)
  end
end
