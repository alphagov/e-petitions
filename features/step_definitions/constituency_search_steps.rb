Given(/^a constituency "(.*?)" is found by postcode "(.*?)"$/) do |constituency_name, postcode|
  @constituencies ||= {}

  constituency = @constituencies[constituency_name]
  if constituency.nil?
    constituency = ConstituencyApi::Constituency.new(FactoryGirl.generate(:constituency_id), constituency_name)
    @constituencies[constituency.name] = constituency
  end

  for_postcode = @constituencies[postcode]
  if for_postcode.nil?
    stub_constituency(postcode, constituency.id, constituency.name)
    @constituencies[postcode] = constituency
  elsif for_postcode == constituency
    # noop
  else
    raise "Postcode #{postcode} registered for constituency #{for_postcode.name} already, can't reassign to #{constituency.name}"
  end
end

Given(/^(a|few|some|many) constituents? in "(.*?)" supports? "(.*?)"$/) do |how_many, constituency, petition_title|
  petition = Petition.find_by!(title: petition_title)
  constituency = @constituencies.fetch(constituency)
  how_many =
    case how_many
    when 'a' then 1
    when 'few' then 3
    when 'some' then 5
    when 'many' then 10
    end

  how_many.times do
    FactoryGirl.create(:pending_signature, petition: petition, constituency_id: constituency.id).validate!
  end
  Petition.update_all_signature_counts
end

When(/^I search for petitions local to me in "(.*?)"$/) do |postcode|
  @my_constituency = @constituencies.fetch(postcode)
  within :css, '.local-to-you' do
    fill_in "UK postcode", with: postcode
    click_on "Search"
  end
end

Then(/^I should see that my fellow constituents support "(.*?)"$/) do |petition_title|
  petition = Petition.find_by!(title: petition_title)
  all_signature_count = petition.signatures.validated.count
  local_signature_count = petition.signatures.validated.where(constituency_id: @my_constituency.id).count
  within :css, '.local-petitions ol' do
    within ".//li[a[.='#{petition_title}']]" do
      expect(page).to have_text("#{local_signature_count} signatures from your constituency")
      expect(page).to have_text("#{all_signature_count} signatures total")
    end
  end
end

Then(/^I should not see that my fellow constituents support "(.*?)"$/) do |petition_title|
  within :css, '.local-petitions ol' do |list|
    expect(list).not_to have_selector(".//li[a[.='#{petition_title}']]")
  end
end

Given(/^the constituency api is down$/) do
  stub_broken_api
end

Then(/^I should see an explanation that my constituency couldn't be found$/) do
  expect(page).not_to have_selector(:css, '.local-petitions ol')
  expect(page).to have_content('We could not find your constituency from the postcode you provided')
end

Then(/^the petitions I see should be ordered by my fellow constituents level of support$/) do
  within :css, '.local-petitions ol' do
    list_elements = page.all(:css, 'li')
    my_constituents_signature_counts = list_elements.map { |li| Integer(li.text.match(/(\d+) signatures from your constituency/)[1]) }
    expect(my_constituents_signature_counts).to eq my_constituents_signature_counts.sort.reverse
  end
end
