Then(/^the petition creator should have been emailed about the scheduled debate$/) do
  @petition.reload
  steps %Q(
    Then "#{@petition.creator.email}" should receive an email
    When they open the email
    Then they should see "MPs are going to debate your petition" in the email body
    When they click the second link in the email
    Then I should be on the petition page for "#{@petition.action}"
  )
end

Then(/^all the signatories of the petition should have been emailed about the scheduled debate$/) do
  @petition.reload
  @petition.signatures.validated.subscribed.where.not(id: @petition.creator.id).each do |signatory|
    steps %Q(
      Then "#{signatory.email}" should receive an email
      When they open the email
      Then they should see "MPs are going to debate the petition" in the email body
      When they click the second link in the email
      Then I should be on the petition page for "#{@petition.action}"
    )
  end
end
