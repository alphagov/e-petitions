csv_cache [I18n.locale, :local_petitions, @constituency], expires_in: 5.minutes do
  CSV.generate do |csv|
    csv << ['Petition', 'URL', 'State', 'Local Signatures', 'Total Signatures']

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
end
