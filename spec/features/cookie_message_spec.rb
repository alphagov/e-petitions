require 'rails_helper'

RSpec.describe 'Cookie message', type: :feature do
  before(:each) { visit home_url }
    
  it 'displays message on first visit' do
    expect(page).to have_text 'We use cookies to make this service simpler'
  end
  
  it 'does not display message on subsequent visits' do
    visit home_url
    expect(page).not_to have_text('We use cookies to make this service simpler')
  end
  
  it 'displays message on subsequent vist after a year' do
    travel(1.send('year') + 1.second)
    visit home_url
    expect(page).to have_text 'We use cookies to make this service simpler'
  end   
end  