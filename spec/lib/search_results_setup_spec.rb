require 'rails_helper'

describe SearchResultsSetup do
  describe "results_for" do
    let (:scope) { double.as_null_object }
    let (:params) { {} }
    subject { Object.extend(SearchResultsSetup) }

    before do
      subject.stub(:params => params)
    end

    it "orders the results by 'signature_count desc' by default" do
      scope.should_receive(:order).with("signature_count desc").and_return(scope)
      subject.results_for(scope)
    end

    it "sets the params to the default of signature_count, desc" do
      subject.results_for(scope)
      params[:order].should == 'desc'
      params[:sort].should == 'count'
    end

    it "orders by closed_at for 'closing'" do
      params[:sort] = 'closing'
      scope.should_receive(:order).with("closed_at asc").and_return(scope)
      subject.results_for(scope)
    end

    it "orders by created_at for 'created'" do
      params[:sort] = 'created'
      scope.should_receive(:order).with("created_at asc").and_return(scope)
      subject.results_for(scope)
    end

    it "keeps the params as they are when passing through the filter" do
      %w{closing created}.each do |order|
        params[:sort] = order
        subject.results_for(scope)
        params[:sort].should == order
      end
    end
  end
end
