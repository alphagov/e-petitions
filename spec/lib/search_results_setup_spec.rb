require 'rails_helper'

describe SearchResultsSetup do
  describe "results_for" do
    let (:scope) { double.as_null_object }
    let (:params) { {} }
    subject { Object.extend(SearchResultsSetup) }

    before do
      allow(subject).to receive_messages(:params => params)
    end

    it "orders the results by 'signature_count desc' by default" do
      expect(scope).to receive(:order).with("signature_count desc").and_return(scope)
      subject.results_for(scope)
    end

    it "sets the params to the default of signature_count, desc" do
      subject.results_for(scope)
      expect(params[:order]).to eq('desc')
      expect(params[:sort]).to eq('count')
    end

    it "orders by closed_at for 'closing'" do
      params[:sort] = 'closing'
      expect(scope).to receive(:order).with("closed_at asc").and_return(scope)
      subject.results_for(scope)
    end

    it "orders by created_at for 'created'" do
      params[:sort] = 'created'
      expect(scope).to receive(:order).with("created_at asc").and_return(scope)
      subject.results_for(scope)
    end

    it "keeps the params as they are when passing through the filter" do
      %w{closing created}.each do |order|
        params[:sort] = order
        subject.results_for(scope)
        expect(params[:sort]).to eq(order)
      end
    end
  end
end
