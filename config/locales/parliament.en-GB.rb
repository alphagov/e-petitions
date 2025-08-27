{
  "en-GB": {
    "parliament": {
      "defaults": {
        "government": "TBC",
        "opening_at": -> { 2.weeks.from_now.change(hour: 10) },
        "dissolved_heading": "We’re waiting for a new Petitions Committee",
        "dissolved_message": <<~EOF
          Petitions had to stop because of the recent general election.
          As soon as a new Petitions Committee is set up by the
          House of Commons, petitions will start again.
        EOF
      }
    }
  }
}
