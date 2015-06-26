require 'rails_helper'

RSpec.describe AdminHelper, type: :helper do
  describe '#admin_petition_facets_for_select' do
    let(:admin_petition_facets) { ['all', 'open', 'awaiting_monkey'] }
    before do
      def helper.admin_petition_facets; end
      allow(helper).to receive(:admin_petition_facets).and_return admin_petition_facets
    end

    let(:selected) { 'open' }
    subject { helper.admin_petition_facets_for_select(selected) }
    before { render text: subject }

    it 'provides an option tag for each facet in admin_petition_facets' do
      expect(rendered).to have_css('option', count: admin_petition_facets.size)
      admin_petition_facets.each.with_index do |facet, idx|
        expect(rendered).to have_css("option:nth-of-type(#{idx+1})[value='#{facet}']")
      end
    end

    it 'sets the text of the option to the value from the locale file if present' do
      expect(rendered).to have_css("option[value='all']", text: I18n.t(:"petitions.facets.names.admin.all"))
    end

    it 'sets the text of the option to the humanized version of the facet name if not present in the locale file if present' do
      expect(rendered).to have_css("option[value='awaiting_monkey']", text: 'Awaiting monkey')
    end

    it 'marks the option whose value matches the supplied argument as selected' do
      expect(rendered).to have_css("option[value='open'][selected]")
    end
  end
end
