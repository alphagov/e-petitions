require 'rake'

module RakeTaskExampleGroup
  extend ActiveSupport::Concern

  included do
    let(:rake) { Rake.application }
    let(:task) { self.class.top_level_description }
    let(:prerequisites) { subject.prerequisites }

    subject { rake[task] }

    around do |example|
      with_rake_env { example.run }
    end
  end

  private

  def application_tasks
    Rails.application.paths['lib/tasks'].to_a
  end

  def with_rake_env
    new_rake = Rake::Application.new
    old_rake, Rake.application = Rake.application, new_rake

    # The Rails enviroment is already loaded so we define an
    # empty environment task to fufill the prerequisites.
    Rake::Task.define_task(:environment)

    # Load just the application tasks defined in `lib/tasks`
    application_tasks.each { |task| load(task) }

    yield

  ensure
    Rake.application = old_rake
  end
end

RSpec.configure do |config|
  config.include RakeTaskExampleGroup, type: :rake, file_path: %r[spec/tasks]
end
