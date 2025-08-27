Given(/^a constituency "(.*?)"(?: with MP "(.*?)")? is found by postcode "(.*?)"$/) do |constituency_name, mp_name, postcode|
  @constituencies ||= {}
  constituency = @constituencies[constituency_name]

  if constituency.nil?
    mp_name = mp_name.present? ? mp_name : 'Rye Tonnemem-Burr MP'
    constituency = FactoryBot.create(:constituency, name: constituency_name, mp_name: mp_name, mp_date: 3.years.ago)
    @constituencies[constituency.name] = constituency
  end

  for_postcode = @constituencies[postcode]

  if for_postcode.nil?
    @constituencies[postcode] = constituency
  elsif for_postcode == constituency
    # noop
  else
    raise "Postcode #{postcode} registered for constituency #{for_postcode.name} already, can’t reassign to #{constituency.name}"
  end
end

Given(/^the MP has passed away$/) do
  @mp_passed_away = true
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
    FactoryBot.create(:pending_signature, petition: petition, constituency_id: constituency.external_id).validate!
  end
end

When(/^I search for petitions local to me in "(.*?)"$/) do |postcode|
  @my_constituency = @constituencies.fetch(postcode)

  if @constituency_api_down
    stub_any_api_request.to_return(api_response(:internal_server_error))
  else
    sanitized_postcode = PostcodeSanitizer.call(postcode)

    if @mp_passed_away
      stub_api_request_for(sanitized_postcode).to_return(api_response(:ok) {
        <<-XML.strip
          <Constituencies>
            <Constituency>
              <Constituency_Id>#{@my_constituency.external_id}</Constituency_Id>
              <Name>#{@my_constituency.name}</Name>
              <ONSCode>#{@my_constituency.ons_code}</ONSCode>
              <RepresentingMembers>
                <RepresentingMember>
                  <Member_Id>#{@my_constituency.mp_id}</Member_Id>
                  <Member>#{@my_constituency.mp_name}</Member>
                  <StartDate>#{@my_constituency.mp_date.iso8601}</StartDate>
                  <EndDate>#{1.day.ago.iso8601}</EndDate>
                </RepresentingMember>
            </Constituency>
          </Constituencies>
        XML
      })
    else
      stub_api_request_for(sanitized_postcode).to_return(api_response(:ok) {
        <<-XML.strip
          <Constituencies>
            <Constituency>
              <Constituency_Id>#{@my_constituency.external_id}</Constituency_Id>
              <Name>#{@my_constituency.name}</Name>
              <ONSCode>#{@my_constituency.ons_code}</ONSCode>
              <RepresentingMembers>
                <RepresentingMember>
                  <Member_Id>#{@my_constituency.mp_id}</Member_Id>
                  <Member>#{@my_constituency.mp_name}</Member>
                  <StartDate>#{@my_constituency.mp_date.iso8601}</StartDate>
                  <EndDate xsi:nil="true"
                           xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>
                </RepresentingMember>
            </Constituency>
          </Constituencies>
        XML
      })
    end
  end

  within :css, '.local-to-you' do
    fill_in "UK postcode", with: postcode
    click_on "Search"
  end
end

Then(/^I should see that my fellow constituents support "(.*?)"$/) do |petition_action|
  petition = Petition.find_by!(action: petition_action)
  all_signature_count = petition.signatures.validated.count
  local_signature_count = petition.signatures.validated.where(constituency_id: @my_constituency.external_id).count
  within :css, '.local-petitions' do
    within ".//*#{XPathHelpers.class_matching('petition-item')}[.//a[.='#{petition_action}']]" do
      expect(page).to have_text("#{local_signature_count} #{'signature'.pluralize(local_signature_count)} from #{@my_constituency.name}")
      expect(page).to have_text("#{all_signature_count} #{'signature'.pluralize(all_signature_count)} total")
    end
  end
end

Then(/^I should not see that my fellow constituents support "(.*?)"$/) do |petition_action|
  within :css, '.local-petitions' do |list|
    expect(list).not_to have_selector(".//*#{XPathHelpers.class_matching('petition-item')}[a[.='#{petition_action}']]")
  end
end

Given(/^the constituency api is down$/) do
  @constituency_api_down = true
end

Then(/^I should see an explanation that my constituency couldn’t be found$/) do
  expect(page).not_to have_selector(:css, '.local-petitions .petition-item')
  expect(page).to have_content("We couldn’t find the postcode")
end

Then(/^I should see an explanation that there are no petitions popular in my constituency$/) do
  within(:css, '.local-petitions') do
    expect(page).not_to have_selector(:css, '.petition-item')
    expect(page).to have_content('No petitions are popular in your constituency')
  end
end

Then(/^the petitions I see should be ordered by my fellow constituents level of support$/) do
  within :css, '.local-petitions ol' do
    petitions = page.all(:css, '.petition-item')
    my_constituents_signature_counts = petitions.map { |petition| Integer(petition.text.match(/(\d+) signatures? from/)[1]) }
    expect(my_constituents_signature_counts).to eq my_constituents_signature_counts.sort.reverse
  end
end

Then(/^I should see a link to the MP for my constituency$/) do
  expect(page).to have_link(@my_constituency.mp_name, href: @my_constituency.mp_url)
end

Then(/^I should not see a link to the MP for my constituency$/) do
  expect(page).not_to have_link(@my_constituency.mp_name, href: @my_constituency.mp_url)
end

Then(/^I should see a link to view all local petitions$/) do
  expect(page).to have_link("View all popular petitions in #{@my_constituency.name}", href: all_local_petition_path(@my_constituency))
end

Then(/^I should see a link to view open local petitions$/) do
  expect(page).to have_link("View open popular petitions in #{@my_constituency.name}", href: local_petition_path(@my_constituency))
end

When(/^I click the view all local petitions$/) do
  click_on "View all popular petitions in #{@my_constituency.name}"
end

Then(/^I should see that closed petitions are identified$/) do
  expect(page).to have_text("now closed")
end

When(/^I click the JSON link$/) do
  click_on "JSON"
end

Then(/^the JSON should be valid$/) do
  expect { JSON.parse(page.body) }.not_to raise_error
end

When(/^I click the CSV link$/) do
  click_on "CSV"
end
