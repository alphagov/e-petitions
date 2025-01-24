class CreatePageContent < ActiveRecord::Migration[7.2]
  class Page < ActiveRecord::Base; end

  def change
    reversible do |dir|
      dir.up do
        Page.create_or_find_by!(slug: 'accessibility') do |page|
          page.title = 'Accessibility statement'
          page.content = <<~MD
            # Accessibility statement

            **We’re committed to making this website accessible so it can be used by as many people as possible.**

            This statement applies to content published within the UK Parliament Petitions website.

            This domain is owned by UK Parliament.

            We aim to make this websites accessible to the widest possible audience. This means, for example, that you should be able to:

            * change colours, contrast levels and fonts
            * zoom in up to 300% without the text spilling off the screen
            * navigate the website using a keyboard
            * navigate the website using speech recognition software
            * listen to the website using a screen reader

            ## What we’re doing to improve accessibility

            To make UK Parliament websites accessible, we:

            * integrate accessibility into our procurement procedures
            * provide accessibility training for our staff
            * include individuals with disabilities in our design personas

            ## How accessible is this website?

            This website should be fully accessible.

            ## How to request content in a different format

            If you need information in a different format please [contact us][1] and tell us:

            * the web address (URL) of the content that you need
            * your contact name and email address
            * the type of format you need

            ## Reporting accessibility problems with this website

            If you find any problems or if you think we’re not meeting the accessibility requirements, please [contact us][1] to report this.

            ## Enforcement procedure

            If you contact us with a complaint and you’re not happy with our response contact the Equality Advisory and Support Service (EASS).

            The Equality and Human Rights Commission (EHRC) is responsible for enforcing the Public Sector Bodies (Websites and Mobile Applications) (No. 2) Accessibility Regulations 2018 (the ‘accessibility regulations’).

            ## Technical information about this website’s accessibility

            UK Parliament is committed to making this website accessible, in accordance with the Public Sector Bodies (Websites and Mobile Applications) (No. 2) Accessibility Regulations 2018.

            ## Compliance status

            This website is compliant with the Web Content Accessibility Guidelines version 2.1 AA standard.

            ## How we tested this website

            Our websites were and are currently being tested for compliance with the Web Content Accessibility Guidelines V2.1 level A and level AA using a combination of automated tools for accessibility WCAG 2.0 standards.

            ## Preparation of this accessibility statement

            This statement was prepared on 21 September 2020.

            This website is being tested via a combination of accessibility tools throughout September 2020. The testing is being carried out by Parliament UK.

            Our sites are checked for accessibility on a regular basis. These tests are carried out by Parliament UK through automated testing via a combination of tools for accessibility.

            [1]: /feedback
          MD
        end

        Page.create_or_find_by!(slug: 'cookies') do |page|
          page.title = 'Cookies'
          page.content = <<~MD
            # Cookies

            This website puts small files (known as ‘cookies’) onto your computer to collect information about how you browse the site.

            These essential cookies are used to:

            * remember the notifications you’ve seen so that we don’t show them to you again
            * help prevent people from fraudulently signing petitions
            * These cookies aren’t used to identify you personally and are strictly necessary to ensure the secure running of this website.

            Find out more about [how to manage cookies][1].

            ## Session cookies

            We store a session cookie on your computer to help keep your information secure while you use the service.

            | Name           | Purpose                                                                                               | Expires                     |
            |----------------|-------------------------------------------------------------------------------------------------------|-----------------------------|
            | _epets_session | This keeps your information secure while you use the petitions service                                | When you close your browser |
            | signed_tokens  | Randomly generated references used to identify what links you’ve clicked to verify your email address | When you close your browser |

            [1]: https://ico.org.uk/your-data-matters/online/cookies
          MD
        end

        Page.create_or_find_by!(slug: 'help') do |page|
          page.title = 'How petitions work'
          page.content = <<~MD
            # How petitions work

            1. You create a petition here on the UK Government and Parliament site. Only British citizens and UK residents can create a petition.
            2. You get 5 people to support your petition. We’ll tell you how to do this when you’ve created your petition.
            3. We check your petition, then publish it. We only reject petitions that don’t meet the standards for petitions.
            4. British citizens and UK residents can then sign your petition — and can only sign a petition once.
            5. The Petitions Committee reviews all petitions we publish. They select petitions of interest to find out more about the issues raised. They have the power to press for action from government or Parliament.
            6. At 10,000 signatures your petition on the UK Government and Parliament site gets a response from the government.
            7. At 100,000 signatures your petition on the UK Government and Parliament site will be considered for a debate in Parliament.

            ## Debates|debates

            Petitions which reach 100,000 signatures are almost always debated. But we may decide not to put a petition forward for debate if the issue has already been debated recently or there’s a debate scheduled for the near future. If that’s the case, we’ll tell you how you can find out more about parliamentary debates on the issue raised by your petition.

            MPs might consider your petition for a debate before it reaches 100,000 signatures.

            We may contact you about the issue covered by your petition. For example, we sometimes invite people who create petitions to take part in a discussion with MPs or government ministers, or to give evidence to a select committee. We may also write to other people or organisations to ask them about the issue raised by your petition.

            ## The Petitions Committee|petitions-committee

            The [Petitions Committee][1] can:

            * write to you for more information
            * invite you to talk to the Committee in person about your petition – this could be in Parliament or somewhere else in the UK
            * ask for evidence from the Government or other relevant people or organisations
            * press the government for action
            * ask another parliamentary committee to look into the topic raised by a petition
            * put forward a petition for debate

            The Petitions Committee is set up by the House of Commons. It comprises up to 11 backbench Members of Parliament from Government and Opposition parties. The number of committee members from each political party is representative of the membership of the House of Commons as a whole.

            ## Standards for petitions|standards

            Petitions must call for a specific action from the UK Government or the House of Commons.

            Petitions must be about something that the Government or the House of Commons is directly responsible for.

            Petitions can disagree with the Government and can ask for it to change its policies. Petitions can be critical of the UK Government or Parliament.

            We reject petitions that don’t meet the rules. If we reject your petition, we’ll tell you why. If we can, we’ll suggest other ways you could raise your issue.

            We’ll have to reject your petition if:

            * It calls for the same action as a petition that’s already open

            * It doesn’t ask for a clear action from the UK Government or the House of Commons

            * It’s about something the UK Government or House of Commons is not directly responsible for.

            * That includes: something that your local council is responsible for; something that another Government (such as the Scottish Government, the Welsh Government or the Northern Ireland Executive) is responsible for; something that is an operational decision for a government or parliamentary body, and something that an independent organisation has done.

            * It calls for action at a local level

            * It calls for action relating to a particular individual, or organisation that the UK Government or Parliament is not responsible for

            * It’s defamatory or libellous, or contains false or unproven statements

            * It refers to a case where there are active legal proceedings

            * It contains material that may be protected by an injunction or court order

            * It contains material that could be confidential or commercially sensitive

            * It could cause personal distress or loss. This includes petitions that could intrude into someone’s personal grief or shock without their consent.

            * It accuses an identifiable person or organisation of wrongdoing, such as committing a crime

            * It names individual officials of public bodies, unless they are senior managers

            * It names family members of elected representatives, eg MPs, or of officials of public bodies

            * It asks for someone to be given an honour, or have an honour taken away. You can nominate someone for an honour here: [www.gov.uk/honours][2]

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

            ## Recall petitions|recall

            If an MP has been convicted of certain criminal offences or suspended from the House of Commons for at least 10 sitting days, they may be subject to a recall petition.

            Petitions to recall Members of Parliament do not appear on this website and the Petitions Committee are not responsible for them. They are run locally, by the returning officer for your area, and have to be signed in person, by post or proxy. Your local authority will have issued a “notice of recall petition” on their website. This will tell you how and when you can sign the petition.

            Find out more about [recall petitions](https://researchbriefings.parliament.uk/ResearchBriefing/Summary/SN05089) here.

            If you have any other questions, please [get in touch][4].

            ## Petitions started on other websites|other-websites

            The Committee will only consider, and the Government is only obliged to respond to, petitions which people have started on the UK Government and Parliament petitions website. The Committee will not consider petitions hosted on external websites.

            [1]: http://www.parliament.uk/petitions-committee
            [2]: https://www.gov.uk/honours
            [3]: https://researchbriefings.parliament.uk/ResearchBriefing/Summary/SN05089
            [4]: /feedback
          MD
        end

        Page.create_or_find_by!(slug: 'privacy') do |page|
          page.title = 'Privacy notice'
          page.content = <<~MD
            # Privacy notice

            Last updated: September 2022

            We respect your right to privacy and manage your personal data in line with our responsibilities under the United Kingdom General Data Protection Regulation (UK GDPR) and Data Protection Act 2018 (DPA 2018). This privacy notice provides the information required by the UK GDPR about the personal data that we collect from you and how we may use your information.

            In this notice, references to ‘us’, ‘our’ or ‘we’ are to the House of Commons; and to ‘you’ or ‘your’ are to an individual whose personal data we process.

            Everything that we do with your personal data – for example, collecting, storing, using, sharing or deleting it – is referred to as “processing”.

            This notice will be updated periodically. We will communicate any significant changes as appropriate.

            ## 1. About us

            The Corporate Officer of the House of Commons (the Clerk of the House) is the Controller of any personal data processed as described in this Privacy Notice.

            The House of Commons Data Protection Officer is the Head of Information Compliance.

            If you have any questions about the use of your personal data, please contact the Information Compliance Team:

            * Email: [hcinformationcompliance@parliament.uk][1]
            * Telephone: 0207 219 4296
            * Post: Information Compliance Team, House of Commons, SW1A 0AA

            ## 2. The personal data we process

            When you contact us, visit us, access or use our services either online, by post, in person or by other means, we may collect, store and use your personal data.

            The personal data we collect from people who start and sign petitions will include: your name, your email address, your postcode, the country you live in, whether you are a British citizen, the IP address you use when starting or signing a petition.

            ## 3. Use of your personal data

            The Petitions service is provided by the House of Commons. Your personal data will be processed for the purposes of starting and signing petitions to raise issues with the UK Government and Parliament.

            We use your personal data to:

            * check that you’re eligible to sign a petition
            * make sure that people only sign a petition once
            * contact you about petitions you start
            * with your consent, send you updates about petitions you have signed.

            If you start a petition and we accept it, your name will be published with the petition for the time it is open for signatures. We won’t publish any other personal information about you.

            If you’ve signed a petition, we won’t publish any personal information about you. We’ll use your postcode to work out how many people in each parliamentary constituency have signed a petition.

            For the purpose of petitions, we consider that the lawful basis for processing your data is that we are engaged in a public task. The processing is necessary for the performance of a public task, namely the exercise of a function of the House of Commons (UK GDPR Article 6 (1) (e) and DPA 2018 (8)). Specifically, processing this data is necessary for the e-petitions website and the work of the Petitions Committee.

            For the purpose of informing you about the status of petitions, we rely on your consent to send updates to an email address provided by you (UK GDPR Article 6(1)(a)).

            Whilst there is no requirement to provide special category data, any information you provide which includes racial or ethnic origin; religious or philosophical beliefs; trade union membership; genetic and biometric data; health data; sex life or sexual orientation will be considered necessary for reasons of substantial public interest, namely the exercise of a function of the House of Commons (UK GDPR Article 9 (2)(g) and DPA 2018 Schedule 1 (7)(b)).

            Our policy for processing special category data can be found here:
            [House of Commons Data Protection information - UK Parliament][2]

            Guidance about the lawful basis for processing personal data can be found on the [Information Commissioner’s website][3]

            ## 4. Sharing your personal data

            We may share or disclose your personal data with:

            * Suppliers and contractors of goods or services contracted by House of Commons in relation to the purpose of fulfilling a public task
            * Other organisations where there is a lawful basis to do so or a duty to disclose in order to comply with any legal obligation. For example, the Police, for the purposes of prevention and detection of crime
            * Unboxed Consulting Limited who provide technical support for the petitions system will have access to the system for troubleshooting and maintenance purposes only.

            We will never share or sell your personal data to other organisations for direct marketing purposes.

            ## 5. Retention and security of your personal data

            We will retain your personal data for as long as is necessary for the purpose it was collected. In most cases, a retention period will apply which can be found in the Houses of Parliament Authorised Records Disposal Policy on our website.

            In relation to Petitions, we will hold your personal data for six months after the dissolution of the current Parliament. A Parliament is the period of parliamentary time between one general election and the next. There are some exceptions as follows:

            * In connection with committee inquiries, we may lawfully retain your personal data for archiving in the public interest and this may amount to indefinite retention.
            * Where the personal data held are subject to the requirements of parliamentary privilege, some individual’s rights under the UK GDPR may not apply in order to prevent an infringement of those privileges.

            However, we will consider individual rights requests in relation to historic evidence on a case-by-case basis. Please also see section 6 of this notice.

            We take the security of your data seriously. All personal data you provide to us (whether electronically or in paper form) will be stored securely in accordance with our policies. We have technical and organisational security measures in place to oversee the effective and secure processing of your personal data and to minimise the possibility of the loss or unauthorised access of your personal data.

            Some personal data controlled by us is held outside the UK, including on data servers in the European Economic Area (EEA). Under the Data Protection Act 2018, all countries within the EEA are regarded as providing an adequate level of data protection. We would not transfer personal data to a person in a country outside the UK or EEA unless satisfied that that person and country had safeguards in place to protect personal data.

            ## 6. Your rights

            We will ensure you can exercise your rights in relation to the personal data you provide to us in accordance with UK GDPR and DPA 2018. Under data protection law, you have the following rights:

            * The right to be informed
            * The right of access
            * The right to rectification
            * The right to erasure
            * The right to restrict processing
            * The right to data portability
            * The right to object
            * Rights in relation to automated decision making and profiling.

            Where we are relying on your consent to use your personal data, you can withdraw that consent at any time by contacting [petitionscommitteeprivacy@parliament.uk][5] or the Data Protection Officer.

            Personal data associated with the signing of an e-petition can only be erased by removing the signature from the petition, in cases where a petition has been signed by mistake or where the requester no longer supports the request of the petition. This is to ensure that validity and accuracy of the total number of signatures on each petition. You can request the removal of your signature from a petition for these reasons by contacting [petitionscommitteeprivacy@parliament.uk][5] or the Data Protection Officer.

            Some of your rights are subject to the exceptions specified in the UK GDPR and Data Protection Act 2018, in particular:

            * Processing for the performance of a public task – some rights do not apply for the processing of personal data for the starting or signing of e-petitions.
            * Parliamentary Privilege - some rights do not apply where required for the purpose of avoiding an infringement of the privileges of either House of Parliament. (para. 13 of Schedule 2 DPA 2018)
            * Archiving in the public interest – some rights do not apply for the processing of personal data for archiving purposes (para. 28 of schedule 2 DPA)

            Please note: Formal Individual Rights Requests are managed by the House of Commons Information Compliance Service who will retain your request, including any relevant personal data, to demonstrate we have met our legal obligations under data protection legislation.  These records are kept securely for two years, after which they are destroyed.

            If you have any concerns relating to the use of your personal data by the Petitions Committee please contact [petitionscommitteeprivacy@parliament.uk][5] in the first instance.

            You may also complain to the Data Protection Officer whose contact details can be found at Section 1.

            You also have the right to complain to the Information Commissioner, the supervisory authority, about our processing of your personal data. They can be contacted at Information Commissioner’s Office, Wycliffe House, Water Lane, Wilmslow, Cheshire, SK9 5AF.

            Further details about your rights can be found on our website, [House of Commons Data Protection information - UK Parliament][6], and the [Information Commissioner’s website][7].

            [1]: mailto:hcinformationcompliance@parliament.uk
            [2]: https://www.parliament.uk/site-information/data-protection/commons-data-protection-information/
            [3]: https://ico.org.uk/for-organisations/guide-to-data-protection/guide-to-the-general-data-protection-regulation-gdpr/lawful-basis-for-processing/
            [4]: https://www.parliament.uk/business/publications/parliamentary-archives/who-we-are/information-records-management-service
            [5]: mailto:petitionscommitteeprivacy@parliament.uk
            [6]: https://www.parliament.uk/site-information/data-protection/commons-data-protection-information/
            [7]: https://ico.org.uk/your-data-matters/
          MD
        end
      end

      dir.down do
        Page.delete_all
      end
    end
  end
end
