require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe JsonRenderer do
  let(:file) { double }
  let(:petitions) { [] }
  subject { JsonRenderer.new }

  before do
    File.stub(:open).and_yield(file)
    FileUtils.stub(:mkdir_p)
  end

  it "renders out the petitions.json" do
    file.should_receive(:write).with(%{[]})
    Petition.should_receive(:visible).and_return(petitions)
    subject.render_all_petitions
  end

  it "renders out the individual petitions" do
    under_threshold = FactoryGirl.create(:open_petition)
    under_threshold.update_attribute(:signature_count, 999)

    over_threshold = FactoryGirl.create(:open_petition)
    over_threshold.update_attribute(:signature_count, 1000)

    over_threshold_but_hidden = FactoryGirl.create(:hidden_petition)
    over_threshold_but_hidden.update_attribute(:signature_count, 1000)

    File.should_receive(:open).with(%r(/public/api/petitions/#{over_threshold.id}.json), "w").once
    file.should_receive(:write).once
    subject.render_individual_over_threshold_petitions
  end
end
