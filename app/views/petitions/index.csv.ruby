csv_builder = lambda do |csv|
  @petitions.find_each do |petition|
    csv << [
      csv_escape(petition.action),
      petition_url(petition),
      petition.state,
      petition.signature_count
    ]
  end
end

headers = %["Petition","URL","State","Signatures Count"\n]

CSV.generate(headers, force_quotes: [0, 1, 2], &csv_builder)
