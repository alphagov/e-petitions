object @petition
attributes :id
node(:postal_districts) { |p| p.signature_counts_by_postal_district }
