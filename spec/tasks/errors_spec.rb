require 'rails_helper'

RSpec.describe "errors:precompile", type: :task do
  let(:public_path) { Pathname.new(Dir.mktmpdir) }

  let(:assets_path) { public_path.join("assets") }
  let(:asset_files) { assets_path.entries.map(&:to_s) }

  let(:errors_path) { public_path.join("errors") }
  let(:error_files) { errors_path.entries.map(&:to_s) }

  let(:propshaft) { Rails.application.assets.load_path }
  let(:error_css) { propshaft.find("error.css").digested_path.to_s }
  let(:error_js) { propshaft.find("error.js").digested_path.to_s }

  before do
    allow(Rails).to receive(:public_path).and_return(public_path)

    subject.invoke
  end

  after do
    FileUtils.remove_entry(public_path)
  end

  it "renders the error pages" do
    expect(error_files).to include('400.html')
    expect(error_files).to include('403.html')
    expect(error_files).to include('404.html')
    expect(error_files).to include('406.html')
    expect(error_files).to include('410.html')
    expect(error_files).to include('422.html')
    expect(error_files).to include('500.html')
    expect(error_files).to include('503.html')

    expect(asset_files).to include(error_css)
    expect(asset_files).to include(error_js)
  end
end
