Then(/^the petition creator should have been emailed about the scheduled debate$/) do
  @petition.reload
  steps %Q(
    Then "#{@petition.creator_signature.email}" should receive an email
    When they open the email
    Then they should see "Parliament is going to debate your petition" in the email body
    When they click the first link in the email
    Then I should be on the petition page for "#{@petition.action}"
  )
end

Then(/^all the signatories of the petition should have been emailed about the scheduled debate$/) do
  @petition.reload
  @petition.signatures.notify_by_email.validated.where.not(id: @petition.creator_signature.id).each do |signatory|
    steps %Q(
      Then "#{signatory.email}" should receive an email
      When they open the email
      Then they should see "Parliament is going to debate the petition" in the email body
      When they click the first link in the email
      Then I should be on the petition page for "#{@petition.action}"
    )
  end
end
