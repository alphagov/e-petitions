require 'rails_helper'

RSpec.describe PetitionHelper, type: :helper do
  describe '#public_petition_facets_with_counts' do
    let(:facets) do
      {
        all: 100,
        open: 10,
        closed: 20,
        rejected: 30,
        awaiting_response: 40,
        with_response: 50,
        awaiting_debate_date: 60,
        with_debate_outcome: 70,
        hidden: 80
      }
    end
    let(:petition_search) { double(facets: facets) }

    subject { helper.public_petition_facets_with_counts(petition_search) }

    it 'returns each facet from the public facet' do
      expect(subject.keys).to eq I18n.t(:'petitions.facets.public')
    end

    it 'returns each facet with its count from the search object' do
      I18n.t(:'petitions.facets.public').each do |public_facet|
        expect(subject[public_facet]).to eq facets[public_facet.to_sym]
      end
    end

    it 'swallows the error and does not expose the facet if the search does not support it' do
      facets.default_proc = ->(_, failed_key) { raise ArgumentError, "Unsupported facet: #{failed_key.inspect}" }
      facets.delete(:with_response)
      expect {
        subject
      }.not_to raise_error
      expect(subject).not_to have_key('with_response')
    end
  end
end
