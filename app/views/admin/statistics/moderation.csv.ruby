CSV.generate do |csv|
  csv << ['Period', 'Percentage moderated within 7 days']

  @rows.each do |row|
    csv << row
  end
end
