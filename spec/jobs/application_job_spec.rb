require 'rails_helper'

RSpec.describe ApplicationJob, type: :job do
  class AnApplicationJob < ::ApplicationJob
    def perform
      logger.info "Performed application job"
    end
  end

  before do
    expect(Site).to receive(:reload).and_call_original
  end

  it "reloads the site instance" do
    perform_enqueued_jobs {
      AnApplicationJob.perform_later
    }
  end
end
