TestAfterCommit.enabled = false

RSpec.configure do |config|
  config.around(:each) do |example|
    if example.metadata.key?(:with_commits)
      TestAfterCommit.with_commits(example.metadata[:with_commits]) do
        example.run
      end
    else
      example.run
    end
  end
end
