Given(/^a constituency "(.*?)" is found by postcode "(.*?)"$/) do |constituency_name, postcode|
  @constituencies ||= {}

  constituency = @constituencies[constituency_name]
  if constituency.nil?
    constituency = ConstituencyApi::Constituency.new(FactoryGirl.generate(:constituency_id), constituency_name)
    @constituencies[constituency.name] = constituency
  end

  for_postcode = @constituencies[postcode]
  if for_postcode.nil?
    body = <<-RESPONSE.strip_heredoc
      <Constituencies>
        <Constituency>
          <Constituency_Id>#{constituency.id}</Constituency_Id>
          <Name>#{constituency.name}</Name>
          <RepresentingMembers>
            <RepresentingMember>
              <Member_Id>0001</Member_Id>
              <Member>A. N. Other MP</Member>
              <StartDate>2015-05-07T00:00:00</StartDate>
              <EndDate xsi:nil="true"
                       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>
            </RepresentingMember>
          </RepresentingMembers>
        </Constituency>
      </Constituencies>
      RESPONSE
    stub_request(:get, "#{ ConstituencyApi::Client::URL }/#{postcode.gsub(/\s+/, '')}/").to_return(status: 200, body: body)
    @constituencies[postcode] = constituency
  elsif for_postcode == constituency
    # noop
  else
    raise "Postcode #{postcode} registered for constituency #{for_postcode.name} already, can't reassign to #{constituency.name}"
  end
end

Given(/^constituents in "(.*?)" support "(.*?)"$/) do |constituency, petition_title|
  petition = Petition.find_by!(title: petition_title)
  constituency = @constituencies.fetch(constituency)
  10.times do
    FactoryGirl.create(:validated_signature, petition: petition, constituency_id: constituency.id)
  end
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
  stub_request(:get, %r[#{ Regexp.escape(ConstituencyApi::Client::URL) }/*]).to_return(status: 500, body: "Daisy, Daisy / Give me your answer, do. / I'm half crazy / all for the love of you.")
end

Then(/^I should see an explanation that my constituency couldn't be found$/) do
  expect(page).not_to have_selector(:css, '.local-petitions ol')
  expect(page).to have_content('We could not find your constituency from the postcode you provided')
end
