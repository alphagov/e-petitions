require 'rails_helper'

RSpec.describe Admin::AdminController, type: :controller do
  context '#admin_petition_facets' do
    it 'extracts the list of admin facets from the locale file' do
      expect(controller.send(:admin_petition_facets)).to eq I18n.t(:"petitions.facets.admin")
    end

    it 'is a helper method' do
      expect(controller.class.helpers).to respond_to :admin_petition_facets
    end
  end
end
