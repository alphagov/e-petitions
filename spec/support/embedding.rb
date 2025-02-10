RSpec.configure do |config|
  config.before(:suite) do
    Embedding.reload
  end

  config.before(:each) do |example|
    Embedding.reload
  end
end
