Given(/^(\d+) (overdue|nearly overdue|recently in) moderation petitions exist$/) do |number, age|
  number.times do
    case age
    when "overdue"
      FactoryGirl.create(:sponsored_petition, :overdue)
    when "nearly overdue"
      FactoryGirl.create(:sponsored_petition, :nearly_overdue)
    when "recently in"
      FactoryGirl.create(:sponsored_petition, :recent)
    end
  end
end

Then(/^the (.*?) panel should have the (.*?) style applied$/) do |panel_name, style_name|
  expect(page).to have_css(".#{panel_name.parameterize}.#{style_name.parameterize}")
end

Then(/^the moderation summary should have the (.*?) style applied$/) do |style_name|
  expect(page).to have_css(".moderation .panel.#{style_name.parameterize}")
end

Then(/^the (.*?) panel should show (\d+)/) do |panel_name, number|
  within(:css, ".#{panel_name.parameterize}") do
    expect(page).to have_content(number)
  end
end
