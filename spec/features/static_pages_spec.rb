require 'rails_helper'

RSpec.describe 'Static Pages', type: :feature do
  describe 'Home Page' do
    before(:each) { visit home_url }

    it 'displays page title and has valid markup' do
      expect(page).to have_title 'Petitions - UK Government and Parliament'
      expect(sanitize_page(page)).to be_valid_markup
    end

    it 'displays help page with new title and has valid markup' do
      click_link 'How petitions work'

      expect(page.current_url).to eq help_url
      expect(page).to have_title 'How petitions work'
      expect(sanitize_page(page)).to be_valid_markup
    end

    it 'displays the privacy page and has valid markup' do
      click_link 'Privacy and cookies'

      expect(page.current_url).to eq privacy_url
      expect(page).to have_title 'Privacy and cookies'
      expect(sanitize_page(page)).to be_valid_markup
    end
  end
end
