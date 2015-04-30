shared_examples "it searches petitions" do |action, search_key, per_page|
  let(:query) { "Rioters should loose benefits" }
  let(:search) { double.as_null_object }

  before(:each) do
    allow(PetitionResults).to receive_messages(:new => search)
  end

  it "is successful" do
    get action, search_key => query
    expect(response).to be_success
  end

  it "finds petitions that match the search query" do
    expect(PetitionResults).to receive(:new).with(hash_including(
      :search_term    => query,
      :per_page       => per_page
    ))
    get action, search_key => query
  end

  it "assigns the results to the view" do
    get action, search_key => query
    expect(assigns(:petition_search)).to eq(search)
  end

  it "passes in state if supplied" do
    expect(PetitionResults).to receive(:new).with(hash_including(
      :state => "closed"
    ))
    get action, search_key => query, :state => "closed"
  end

  it "passes in order if supplied" do
    expect(PetitionResults).to receive(:new).with(hash_including(
      :order => 'asc'
    ))
    get action, search_key => query, :order => 'asc'
  end

  it "passes in state if supplied" do
    expect(PetitionResults).to receive(:new).with(hash_including(
      :sort => 'title'
    ))
    get action, search_key => query, :sort => 'title'
  end
end
