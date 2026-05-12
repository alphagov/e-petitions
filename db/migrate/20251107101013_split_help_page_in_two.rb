class SplitHelpPageInTwo < ActiveRecord::Migration[8.0]
  class Page < ActiveRecord::Base
    class << self
      def create_or_update_by!(attributes, &block)
        page = create_or_find_by!(attributes, &block)

        unless page.previously_new_record?
          yield page
          page.save!
        end
      end
    end
  end

  def change
    reversible do |dir|
      dir.up do
        Page.create_or_update_by!(slug: 'help') do |page|
          page.title = 'How petitions work'
          page.content = <<~MD
            # How to create an e-petition

            You can call for action from the UK Government or UK Parliament by creating and submitting an e-petition.

            These are online petitions created on [petition.parliament.uk][1].

            Once a petition is published, it is open for 6 months to gather signatures.

            * If an e-petition receives 10,000 signatures, it will receive a response from the Government.
            * If it receives 100,000 signatures it may be debated in Parliament.

            ## Creating and submitting an e-petition

            You can start an e-petition on the website.

            You’ll be asked to:

            * write a clear petition action
            * provide details about what you want to happen and why
            * get five supporters for your petition so it can be checked by the petitions team.

            You’ll also need to make sure it meets the standards for petitions.

            ## Who can create an e-petition?

            British citizens and UK residents can create an e-petition.

            ## What e-petitions can be about

            E-petitions must ask for a clear action from the UK Government or Parliament.

            The petition must also be about something the UK Government or Parliament is responsible for. For example, if it’s something your local council is responsible for, you’ll need to [contact your local council instead][2].

            Your petition will be rejected if it doesn’t meet these requirements.

            ## Standards for e-petitions

            E-petitions must also meet the standards for petitions before they can be accepted and published on the open petitions page.

            Your petition will be rejected if it does not meet [the standards for petitions][3].

            ## Petitions created on other websites

            The Government is only obliged to respond to e-petitions started on [petition.parliament.uk][1]. The Petitions Committee also only considers e-petitions started on [petition.parliament.uk][1] for debate.

            ## How to start an e-petition

            The [e-petition form][4] asks you to:

            * confirm you’re a British citizen or UK resident
            * summarise what you want the UK Government or Parliament to do
            * check there isn’t already a petition asking for a similar action
            * give more details about what you want to happen, and why.

            You’ll then be asked to:

            * check your petition and make any final changes
            * sign your petition
            * confirm your full name, email address, and UK postcode
            * confirm whether you’d like to get updates about your petition
            * submit the form.

            ## After you’ve finished creating your petition

            When you’ve completed the form, you’ll receive an email with:

            * the full petition text
            * a link for your supporters to sign it.

            ## How to get supporters for your petition

            Share your petition with people who might be willing to support it.

            They must be British citizens or UK residents.

            They can confirm their support for your petition by clicking on the link.

            You need five people to support your petition. At this stage, a maximum of 21 people can sign your petition.

            ## Publication of your petition

            Once five people have signed your petition, we’ll check it meets the standards for e-petitions.

            ## If your petition meets the standards

            Your petition will be published on the [open petitions page][5]. British citizens and UK residents will be able to sign your petition. Your petition will stay open for six months to gather signatures.

            ## If your petition doesn’t meet the standards

            If your petition doesn’t meet the standards for petitions, it will be rejected and will not be open to collect signatures.

            You'll receive information about why this happened. You can start again with a new petition.

            There are examples on the [rejected petitions page][6]. They can be viewed but not signed.

            ## Once your petition has been published

            What happens next depends on how many signatures your petition gets.

            ### Petitions with 10,000 or more signatures

            Petitions that get 10,000 signatures get a response from the UK Government.

            The response is provided by the government department responsible for the petition topic. It appears on the same page as the petition, along with the publication date.

            Petitions with responses from the UK Government are available on the [government responses page][13].

            ### Petitions with more than 100,000 signatures

            The Petitions Committee has the power to arrange debates on petitions. All petitions that get 100,000 signatures will be considered for debate, and are usually debated.

            The committee might decide not to arrange a debate on a petition. For example, this might happen if the issue:

            * has already been debated recently
            * is scheduled for debate in the near future.

            If this happens, we’ll email you with further information.

            ## The Petitions Committee|petitions-committee

            The Petitions Committee is a group of 11 MPs from government and opposition parties who consider e-petitions. The committee may contact you about the issue covered by your petition.

            Read [more about the Petitions Committee][8].

            ## Contact the Petitions Committee team

            The Petitions Committee team can:

            * answer queries about how Parliament handles petitions
            * help with questions about how to use this service.

            They can't:

            * forward feedback to the people who started a petition
            * comment on the ideas raised in a specific petition.

            Email: petitionscommittee@parliament.uk

            ### Phone enquiries

            Phone calls are handled by the House of Commons Enquiry Service. You can call them Monday to Friday, 10am to 12pm and 2pm to 4pm.

            The enquiry service can help you to understand how Parliament handles petitions.

            They can’t:

            * help with technical problems with this service
            * forward your feedback to the people who started a petition
            * comment on the ideas raised in a specific petition.

            Phone: 0800 112 4272 (Freephone) or 020 7219 4272

            Text Relay: 18001 followed by 020 7219 4272

            ## Feedback
            [Give feedback][10] about the UK Government and Parliament petitions website.

            ## Further information

            ### Paper petitions
            You can [ask your MP to present a paper petition to the House of Commons][11].

            The rules for this type of petition are different. They can be about local issues, for example.

            ### Petitions to recall Members of Parliament

            Petitions to recall Members of Parliament are known as ‘recall petitions’.

            They do not appear on this website and the Petitions Committee are not responsible for them.

            Find out more about recall petitions on [the Electoral Commission website][12].

            [1]: https://petition.parliament.uk
            [2]: https://www.gov.uk/find-local-council
            [3]: /help#standards
            [4]: /petitions/start
            [5]: /petitions?state=open
            [6]: /petitions?state=rejected
            [7]: https://www.gov.uk/honours
            [8]: https://www.parliament.uk/petitions-committee
            [9]: mailto:petitionscommittee@parliament.uk
            [10]: /feedback
            [11]: https://www.parliament.uk/get-involved/sign-a-petition/paper-petitions/
            [12]: https://www.electoralcommission.org.uk/voting-and-elections/how-elections-work/types-elections/recall-petitions
            [13]: /petitions?state=with_response
          MD
        end

        Page.create_or_update_by!(slug: 'standards') do |page|
          page.title = 'Standards for petitions'
          page.content = <<~MD
            # Standards for petitions

            Petitions must call for a specific action from the UK Government or the House of Commons.

            Petitions must be about something that the Government or the House of Commons is directly responsible for.

            Petitions can disagree with the Government and can ask for it to change its policies.

            Petitions can be critical of the UK Government or Parliament.

            We reject petitions that don’t meet the rules. If we reject your petition, we’ll tell you why. If we can, we’ll suggest other ways you could raise your issue.

            We’ll have to reject your petition if:

            * It calls for the same action as a petition that’s already open
            * It doesn’t ask for a clear action from the UK Government or the House of Commons
            * It’s about something the UK Government or House of Commons is not directly responsible for.
            * That includes: something that your local council is responsible for; something that another Government (such as the Scottish Government, the Welsh Government or the Northern Ireland Executive) is responsible for; something that is an operational decision for a government or parliamentary body, and something that an independent organisation has done.
            * It calls for action at a local level
            * It calls for action relating to a particular individual, or organisation that the UK Government or Parliament is not responsible for – except where the organisation’s role or powers are set out in law, and the petition is to amend that law.
            * It’s defamatory or libellous, or contains false or unproven statements
            * It refers to a case where there are active legal proceedings
            * It contains material that may be protected by an injunction or court order
            * It contains material that could be confidential or commercially sensitive
            * It could cause personal distress or loss. This includes petitions that could intrude into someone’s personal grief or shock without their consent.
            * It accuses an identifiable person or organisation of wrongdoing, such as committing a crime
            * It names individual officials of public bodies, unless they are senior managers
            * It names family members of elected representatives, eg MPs, or of officials of public bodies
            * It asks for someone to be given an honour, or have an honour taken away. You can nominate someone for an honour here: [www.gov.uk/honours][1]
            * It asks for someone to be given a job, or to lose their job. This includes petitions calling for someone to resign and petitions asking for a vote of no confidence in an individual Minister or the Government as a whole
            * It contains party political material
            * It’s nonsense or a joke
            * It’s an advert, spam, or promotes a specific product or service
            * It’s a Freedom of Information request
            * It contains swearing or other offensive language
            * It’s offensive or extreme in its views. That includes petitions that attack, criticise or negatively focus on an individual or a group of people because of characteristics such as their age, disability, ethnic origin, gender identity, medical condition, nationality, race, religion, sex, or sexual orientation
            * It contains material that it wouldn’t be appropriate to publish as a parliamentary petition

            We publish the text of petitions that we reject, as long as they’re not:

            * defamatory, libellous or illegal in another way;
            * making false or unproven statements;
            * about a case there are active legal proceedings or about something that a court has issued an injunction over;
            * about an individual person, or organisation that the UK Government or Parliament is not responsible for;
            * offensive or extreme;
            * confidential or likely to cause personal distress. That includes petitions that could intrude into someone’s personal grief or shock without their consent;
            * a joke, an advert or nonsense; or
            * containing material that it wouldn’t be appropriate to publish as a parliamentary petition.

            [1]: https://www.gov.uk/honours
          MD
        end
      end

      dir.down do
        Page.create_or_update_by!(slug: 'help') do |page|
          page.title = 'How petitions work'
          page.content = <<~MD
            # How to create an e-petition

            You can call for action from the UK Government or UK Parliament by creating and submitting an e-petition.

            These are online petitions created on [petition.parliament.uk][1].

            Once a petition is published, it is open for 6 months to gather signatures.

            * If an e-petition receives 10,000 signatures, it will receive a response from the Government.
            * If it receives 100,000 signatures it may be debated in Parliament.

            ## Creating and submitting an e-petition

            You can start an e-petition on the website.

            You’ll be asked to:

            * write a clear petition action
            * provide details about what you want to happen and why
            * get five supporters for your petition so it can be checked by the petitions team.

            You’ll also need to make sure it meets the standards for petitions.

            ## Who can create an e-petition?

            British citizens and UK residents can create an e-petition.

            ## What e-petitions can be about

            E-petitions must ask for a clear action from the UK Government or Parliament.

            The petition must also be about something the UK Government or Parliament is responsible for. For example, if it’s something your local council is responsible for, you’ll need to [contact your local council instead][2].

            Your petition will be rejected if it doesn’t meet these requirements.

            ## Standards for e-petitions

            E-petitions must also meet the standards for petitions before they can be accepted and published on the open petitions page.

            Your petition will be rejected if it does not meet [the standards for petitions][3].

            ## Petitions created on other websites

            The Government is only obliged to respond to e-petitions started on [petition.parliament.uk][1]. The Petitions Committee also only considers e-petitions started on [petition.parliament.uk][1] for debate.

            ## How to start an e-petition

            The [e-petition form][4] asks you to:

            * confirm you’re a British citizen or UK resident
            * summarise what you want the UK Government or Parliament to do
            * check there isn’t already a petition asking for a similar action
            * give more details about what you want to happen, and why.

            You’ll then be asked to:

            * check your petition and make any final changes
            * sign your petition
            * confirm your full name, email address, and UK postcode
            * confirm whether you’d like to get updates about your petition
            * submit the form.

            ## After you’ve finished creating your petition

            When you’ve completed the form, you’ll receive an email with:

            * the full petition text
            * a link for your supporters to sign it.

            ## How to get supporters for your petition

            Share your petition with people who might be willing to support it.

            They must be British citizens or UK residents.

            They can confirm their support for your petition by clicking on the link.

            You need five people to support your petition. At this stage, a maximum of 21 people can sign your petition.

            ## Publication of your petition

            Once five people have signed your petition, we’ll check it meets the standards for e-petitions.

            ## If your petition meets the standards

            Your petition will be published on the [open petitions page][5]. British citizens and UK residents will be able to sign your petition. Your petition will stay open for six months to gather signatures.

            ## If your petition doesn’t meet the standards

            If your petition doesn’t meet the standards for petitions, it will be rejected and will not be open to collect signatures.

            You'll receive information about why this happened. You can start again with a new petition.

            There are examples on the [rejected petitions page][6]. They can be viewed but not signed.

            ## Standards for petitions|standards

            Petitions must call for a specific action from the UK Government or the House of Commons.

            Petitions must be about something that the Government or the House of Commons is directly responsible for.

            Petitions can disagree with the Government and can ask for it to change its policies.

            Petitions can be critical of the UK Government or Parliament.

            We reject petitions that don’t meet the rules. If we reject your petition, we’ll tell you why. If we can, we’ll suggest other ways you could raise your issue.

            We’ll have to reject your petition if:

            * It calls for the same action as a petition that’s already open
            * It doesn’t ask for a clear action from the UK Government or the House of Commons
            * It’s about something the UK Government or House of Commons is not directly responsible for.
            * That includes: something that your local council is responsible for; something that another Government (such as the Scottish Government, the Welsh Government or the Northern Ireland Executive) is responsible for; something that is an operational decision for a government or parliamentary body, and something that an independent organisation has done.
            * It calls for action at a local level
            * It calls for action relating to a particular individual, or organisation that the UK Government or Parliament is not responsible for – except where the organisation’s role or powers are set out in law, and the petition is to amend that law.
            * It’s defamatory or libellous, or contains false or unproven statements
            * It refers to a case where there are active legal proceedings
            * It contains material that may be protected by an injunction or court order
            * It contains material that could be confidential or commercially sensitive
            * It could cause personal distress or loss. This includes petitions that could intrude into someone’s personal grief or shock without their consent.
            * It accuses an identifiable person or organisation of wrongdoing, such as committing a crime
            * It names individual officials of public bodies, unless they are senior managers
            * It names family members of elected representatives, eg MPs, or of officials of public bodies
            * It asks for someone to be given an honour, or have an honour taken away. You can nominate someone for an honour here: [www.gov.uk/honours][7]
            * It asks for someone to be given a job, or to lose their job. This includes petitions calling for someone to resign and petitions asking for a vote of no confidence in an individual Minister or the Government as a whole
            * It contains party political material
            * It’s nonsense or a joke
            * It’s an advert, spam, or promotes a specific product or service
            * It’s a Freedom of Information request
            * It contains swearing or other offensive language
            * It’s offensive or extreme in its views. That includes petitions that attack, criticise or negatively focus on an individual or a group of people because of characteristics such as their age, disability, ethnic origin, gender identity, medical condition, nationality, race, religion, sex, or sexual orientation
            * It contains material that it wouldn’t be appropriate to publish as a parliamentary petition

            We publish the text of petitions that we reject, as long as they’re not:

            * defamatory, libellous or illegal in another way;
            * making false or unproven statements;
            * about a case there are active legal proceedings or about something that a court has issued an injunction over;
            * about an individual person, or organisation that the UK Government or Parliament is not responsible for;
            * offensive or extreme;
            * confidential or likely to cause personal distress. That includes petitions that could intrude into someone’s personal grief or shock without their consent;
            * a joke, an advert or nonsense; or
            * containing material that it wouldn’t be appropriate to publish as a parliamentary petition.

            ## Once your petition has been published

            What happens next depends on how many signatures your petition gets.

            ### Petitions with 10,000 or more signatures

            Petitions that get 10,000 signatures get a response from the UK Government.

            The response is provided by the government department responsible for the petition topic. It appears on the same page as the petition, along with the publication date.

            Petitions with responses from the UK Government are available on the [government responses page][13].

            ### Petitions with more than 100,000 signatures

            The Petitions Committee has the power to arrange debates on petitions. All petitions that get 100,000 signatures will be considered for debate, and are usually debated.

            The committee might decide not to arrange a debate on a petition. For example, this might happen if the issue:

            * has already been debated recently
            * is scheduled for debate in the near future.

            If this happens, we’ll email you with further information.

            ## The Petitions Committee|petitions-committee

            The Petitions Committee is a group of 11 MPs from government and opposition parties who consider e-petitions. The committee may contact you about the issue covered by your petition.

            Read [more about the Petitions Committee][8].

            ## Contact the Petitions Committee team

            The Petitions Committee team can:

            * answer queries about how Parliament handles petitions
            * help with questions about how to use this service.

            They can't:

            * forward feedback to the people who started a petition
            * comment on the ideas raised in a specific petition.

            Email: petitionscommittee@parliament.uk

            ### Phone enquiries

            Phone calls are handled by the House of Commons Enquiry Service. You can call them Monday to Friday, 10am to 12pm and 2pm to 4pm.

            The enquiry service can help you to understand how Parliament handles petitions.

            They can’t:

            * help with technical problems with this service
            * forward your feedback to the people who started a petition
            * comment on the ideas raised in a specific petition.

            Phone: 0800 112 4272 (Freephone) or 020 7219 4272

            Text Relay: 18001 followed by 020 7219 4272

            ## Feedback
            [Give feedback][10] about the UK Government and Parliament petitions website.

            ## Further information

            ### Paper petitions
            You can [ask your MP to present a paper petition to the House of Commons][11].

            The rules for this type of petition are different. They can be about local issues, for example.

            ### Petitions to recall Members of Parliament

            Petitions to recall Members of Parliament are known as ‘recall petitions’.

            They do not appear on this website and the Petitions Committee are not responsible for them.

            Find out more about recall petitions on [the Electoral Commission website][12].

            [1]: https://petition.parliament.uk
            [2]: https://www.gov.uk/find-local-council
            [3]: /help#standards
            [4]: /petitions/start
            [5]: /petitions?state=open
            [6]: /petitions?state=rejected
            [7]: https://www.gov.uk/honours
            [8]: https://www.parliament.uk/petitions-committee
            [9]: mailto:petitionscommittee@parliament.uk
            [10]: /feedback
            [11]: https://www.parliament.uk/get-involved/sign-a-petition/paper-petitions/
            [12]: https://www.electoralcommission.org.uk/voting-and-elections/how-elections-work/types-elections/recall-petitions
            [13]: /petitions?state=with_response
          MD
        end

        Page.delete_by(slug: 'standards')
      end
    end
  end
end
