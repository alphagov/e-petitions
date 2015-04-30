require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe JsonRenderer do
  let(:file) { double }
  let(:petitions) { [] }
  subject { JsonRenderer.new }

  before do
    allow(File).to receive(:open).and_yield(file)
    allow(FileUtils).to receive(:mkdir_p)
  end

  it "renders out the petitions.json" do
    expect(file).to receive(:write).with(%{[]})
    expect(Petition).to receive(:visible).and_return(petitions)
    subject.render_all_petitions
  end

  it "renders out the individual petitions" do
    under_threshold = FactoryGirl.create(:open_petition)
    under_threshold.update_attribute(:signature_count, 999)

    over_threshold = FactoryGirl.create(:open_petition)
    over_threshold.update_attribute(:signature_count, 1000)

    over_threshold_but_hidden = FactoryGirl.create(:hidden_petition)
    over_threshold_but_hidden.update_attribute(:signature_count, 1000)

    expect(File).to receive(:open).with(%r(/public/api/petitions/#{over_threshold.id}.json), "w").once
    expect(file).to receive(:write).once
    subject.render_individual_over_threshold_petitions
  end
end
