require 'rails_helper'

describe SearchController do
  describe "GET 'search'" do
    it_should_behave_like "it searches petitions", :search, :q, 20 do
      it "passes in page number if supplied" do
        expect(PetitionResults).to receive(:new).with(hash_including(
          :page_number => "4"
        ))
        get :search, :q => query, :page => "4"
      end
    end
  end
end
