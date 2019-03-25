RSpec.configure do |config|
  helpers = Module.new do
    def without_cache(key, options = {}, &block)
      value = Rails.cache.read(key)
      Rails.cache.delete(key)

      yield

    ensure
      Rails.cache.delete(key)
      Rails.cache.write(key, value, options)
    end
  end

  config.include helpers
end
