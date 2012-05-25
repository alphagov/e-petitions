shared_examples "it searches petitions" do |action, search_key, per_page|
  let(:query) { "Rioters should loose benefits" }
  let(:search) { double.as_null_object }

  before(:each) do
    PetitionResults.stub(:new => search)
  end

  it "is successful" do
    get action, search_key => query
    response.should be_success
  end

  it "finds petitions that match the search query" do
    PetitionResults.should_receive(:new).with(hash_including(
      :search_term    => query,
      :per_page       => per_page
    ))
    get action, search_key => query
  end

  it "assigns the results to the view" do
    get action, search_key => query
    assigns(:petition_search).should == search
  end

  it "passes in state if supplied" do
    PetitionResults.should_receive(:new).with(hash_including(
      :state => "closed"
    ))
    get action, search_key => query, :state => "closed"
  end

  it "passes in order if supplied" do
    PetitionResults.should_receive(:new).with(hash_including(
      :order => 'asc'
    ))
    get action, search_key => query, :order => 'asc'
  end

  it "passes in state if supplied" do
    PetitionResults.should_receive(:new).with(hash_including(
      :sort => 'title'
    ))
    get action, search_key => query, :sort => 'title'
  end
end
