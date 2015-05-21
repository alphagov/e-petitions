Then /^I see the following reports table:$/ do |values_table|
  actual_table = find(:css, 'table.admin_report').all(:css, 'tr').map { |row| row.all(:css, 'th, td').map { |cell| cell.text.strip } }
  values_table.diff!(actual_table)
end

Then /^I should see trending petitions for the last (\d+) (hours|days)$/ do |time_period, hours_or_days|
  (11..15).each do |petition_number|
    expect(page).to have_css("tr.trending_petition td.title", :text => "Petition #{petition_number}")
    expect(page).to have_css("tr.trending_petition td.count", :text => "#{petition_number+1}")
  end
end

Given /^there has been activity on a number of petitions in the last (\d+) (hours|days)$/ do |number_of_days, hours_or_days|
  (1..15).each do |count|
    petition = FactoryGirl.create(:open_petition, :title => "Petition #{count}")
    timestamp = (number_of_days - 1).send(hours_or_days).ago
    count.times { FactoryGirl.create(:validated_signature, :petition => petition, :updated_at => timestamp) }
  end
end

Then /^I choose to view (\d+) days of trends$/ do |arg1|
  select '7', :from => :number_of_days_to_trend
  click_button "Go"
end
