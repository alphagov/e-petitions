require 'rails_helper'

RSpec.describe "db:migrate:wait", type: :task do
  before do
    allow(Kernel).to receive(:sleep)
  end

  it "runs the migrations" do
    expect(ActiveRecord::Tasks::DatabaseTasks).to receive(:migrate_all).once

    subject.invoke
  end

  it "retries when another server is migrating the database" do
    attempts = 0

    expect(ActiveRecord::Tasks::DatabaseTasks).to receive(:migrate_all).exactly(3).times do
      raise ActiveRecord::ConcurrentMigrationError if (attempts += 1) < 3
    end

    expect { subject.invoke }.to output(/Another server is migrating the database/).to_stdout
    expect(Kernel).to have_received(:sleep).with(5).twice
  end

  it "gives up after 60 attempts" do
    expect(ActiveRecord::Tasks::DatabaseTasks).to receive(:migrate_all).exactly(60).times.and_raise(ActiveRecord::ConcurrentMigrationError)

    expect {
      expect { subject.invoke }.to output.to_stdout
    }.to raise_error(ActiveRecord::ConcurrentMigrationError)
  end
end
