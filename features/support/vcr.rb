VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = true
  c.cassette_library_dir = 'features/support/vcr_casettes'
  c.hook_into :webmock
  c.ignore_localhost = true
end
