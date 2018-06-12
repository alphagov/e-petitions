require 'rails_helper'

RSpec.describe "assets:precompile", type: :task do
  it "includes 'errors:precompile' in its prerequisites" do
    expect(prerequisites).to include('errors:precompile')
  end
end
