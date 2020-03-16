Given(/^petitions are collecting signatures$/) do
  allow_any_instance_of(Site).to receive(:disable_collecting_signatures).and_return(false)
end

Given(/^petitions are not collecting signatures$/) do
  allow_any_instance_of(Site).to receive(:disable_collecting_signatures).and_return(true)

  home_page_message = <<~MESSAGE
    ### Petitions have stopped collecting signatures

    With the nation currently facing extremely challenging circumstances due to coronavirus (COVID-19), Parliament has been closed and can’t debate petitions. As a consequence we have stopped collecting signatures on petitions. Once Parliament has reconvened we will allow signature collection to begin again.

    For further information please see [the Parliament web site][1].

    [1]: https://www.parliament.uk/business/news/2020/march/uk-parliament-coronavirus-update/
  MESSAGE

  petition_page_message = <<~MESSAGE
    ### This petition has stopped collecting signatures

    With the nation currently facing extremely challenging circumstances due to coronavirus (COVID-19), Parliament has been closed and can’t debate petitions. As a consequence we have stopped collecting signatures on petitions. Once Parliament has reconvened we will allow signature collection to begin again.

    For further information please see [the Parliament web site][1].

    [1]: https://www.parliament.uk/business/news/2020/march/uk-parliament-coronavirus-update/
  MESSAGE

  allow(Site).to receive(:home_page_message).and_return(home_page_message)
  allow(Site).to receive(:petition_page_message).and_return(petition_page_message)
end

Given(/^a home page message has been enabled$/) do
  allow_any_instance_of(Site).to receive(:show_home_page_message).and_return(true)

  message = <<~MESSAGE
    ### Petition moderation is experiencing delays

    Thank you to everyone who’s starting or signing petitions at the moment.

    We’re working to check the new petitions you’ve submitted as quickly as we can, but we’ve got a lot more than usual, so it might take us longer than our usual 7 days.

    For further information about Petitions please see [the Parliament web site][1].

    [1]: https://committees.parliament.uk/committee/326/petitions-committee/content/145126/find-out-more-about-epetitions/
  MESSAGE

  allow(Site).to receive(:home_page_message).and_return(message)
end

Given(/^a petition page message has been enabled$/) do
  allow_any_instance_of(Site).to receive(:show_petition_page_message).and_return(true)

  message = <<~MESSAGE
    ### We are experiencing delays when signing this petition

    Due to unprecedented demand we are experiencing delays delivering emails.
  MESSAGE

  allow(Site).to receive(:petition_page_message).and_return(message)
end
