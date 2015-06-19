Given(/^a constituency "(.*?)"(?: with MP "(.*?)")? is found by postcode "(.*?)"$/) do |constituency_name, mp_name, postcode|
  @constituencies ||= {}

  constituency = @constituencies[constituency_name]
  if constituency.nil?
    mp_name = mp_name.present? ? mp_name : 'Rye Tonnemem-Burr MP'
    mp = ConstituencyApi::Mp.new(FactoryGirl.generate(:mp_id), mp_name, 3.years.ago)
    constituency = ConstituencyApi::Constituency.new(FactoryGirl.generate(:constituency_id), constituency_name, mp)
    @constituencies[constituency.name] = constituency
  end

  for_postcode = @constituencies[postcode]
  if for_postcode.nil?
    stub_constituency(postcode, constituency.id, constituency.name, mp_id: constituency.mp.id, mp_name: constituency.mp.name, mp_start_date: constituency.mp.start_date )
    @constituencies[postcode] = constituency
  elsif for_postcode == constituency
    # noop
  else
    raise "Postcode #{postcode} registered for constituency #{for_postcode.name} already, can't reassign to #{constituency.name}"
  end
end

Given(/^(a|few|some|many) constituents? in "(.*?)" supports? "(.*?)"$/) do |how_many, constituency, petition_action|
  petition = Petition.find_by!(action: petition_action)
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

Then(/^I should see that my fellow constituents support "(.*?)"$/) do |petition_action|
  petition = Petition.find_by!(action: petition_action)
  all_signature_count = petition.signatures.validated.count
  local_signature_count = petition.signatures.validated.where(constituency_id: @my_constituency.id).count
  within :css, '.local-petitions ol' do
    within ".//li[a[.='#{petition_action}']]" do
      expect(page).to have_text("#{local_signature_count} signatures from your constituency")
      expect(page).to have_text("#{all_signature_count} signatures total")
    end
  end
end

Then(/^I should not see that my fellow constituents support "(.*?)"$/) do |petition_action|
  within :css, '.local-petitions ol' do |list|
    expect(list).not_to have_selector(".//li[a[.='#{petition_action}']]")
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

Then(/^I should see a link to the MP for my constituency$/) do
  expect(page).to have_link(@my_constituency.mp.name, href: @my_constituency.mp.url)
end
