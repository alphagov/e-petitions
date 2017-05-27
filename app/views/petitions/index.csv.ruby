csv_builder = lambda do |csv|
  csv << ['Petition', 'URL', 'State', 'Signatures Count']

  @petitions.find_each do |petition|
    csv << [
      petition.action,
      petition_url(petition),
      petition.state,
      petition.signature_count
    ]
  end
end

if @petitions.query.present?
  CSV.generate(&csv_builder)
else
  csv_cache [:petitions, @petitions.scope], expires_in: 5.minutes do
    CSV.generate(&csv_builder)
  end
end
