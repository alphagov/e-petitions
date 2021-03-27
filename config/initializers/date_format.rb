Time::DATE_FORMATS[:stepped_cache_key] = lambda { |time|
  (time.floor - time.to_i % 5).to_s(:usec)
}
