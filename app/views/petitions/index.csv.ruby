csv_builder = lambda do |csv|
  csv << ['Petition', 'URL', 'State', 'Signatures Count', 'Created At', 'Opened At', 'Closed At']

  @petitions.find_each do |petition|
    csv << [
      csv_escape(petition.action),
      petition_url(petition),
      petition.state,
      petition.signature_count,
      petition.created_at.iso8601,
      petition.opened_at.iso8601,
      petition.closed_at.iso8601,
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
