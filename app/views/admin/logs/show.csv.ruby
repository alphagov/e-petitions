CSV.generate do |csv|
  csv << ['ip_address', 'timestamp', 'method', 'uri', 'user_agent']

  @logs.each do |log|
    csv << [
      log.ip_address,
      api_date_format(log.timestamp),
      log.method,
      log.uri,
      log.agent
    ]
  end
end
