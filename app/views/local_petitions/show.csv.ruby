csv_builder = lambda do |csv|
  @petitions.each do |petition|
    csv << [
      csv_escape(petition.action),
      petition_url(petition),
      petition.state,
      petition.constituency_signature_count,
      petition.signature_count
    ]
  end
end

headers = %["Petition","URL","State","Local Signatures","Total Signatures"\n]

CSV.generate(headers, force_quotes: [0, 1, 2], &csv_builder)
