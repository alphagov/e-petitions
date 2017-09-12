require 'rails_helper'

RSpec.describe 'Email validation' do
  subject { EMAIL_REGEX }

  it 'matches simple email addresses' do
    expect(subject).to match('laura@example.com')
  end

  it 'matches subdomain email addresses' do
    expect(subject).to match('laura@subdomain.example.com')
  end

  it 'matches email addresses with uncommon tld' do
    expect(subject).to match('laura@example.photography')
    expect(subject).to match('laura@example.london')
    expect(subject).to match('laura@example.averylongtldname')
  end

  it 'matches email addresses with single characters' do
    expect(subject).to match('l@s.c')
  end

  it 'matches email addresses with special characters' do
    expect(subject).to match('laura@!\"\#$%(),/;<>_[]\`|.com')
    expect(subject).to match('laura!\"\#$%()@example.com')
  end

  it 'doesn\'t match email addresses without a domain and tld' do
    expect(subject).to_not match('laura@example')
  end

  it 'doesn\'t match email addresses without a local' do
    expect(subject).to_not match('@example.com')
  end

  it 'doesn\'t match email addresses without at sign' do
    expect(subject).to_not match('laura')
    expect(subject).to_not match('laura.example.com')
  end

  it 'doesn\'t match email addresses with a space character' do
    expect(subject).to_not match('laura@example. com')
    expect(subject).to_not match('laura@ example.com')
    expect(subject).to_not match('laura space@example.com')
  end

  it 'doesn\'t match email addresses with at sign in local, sld or tld' do
    expect(subject).to_not match('laura@123@example.com')
    expect(subject).to_not match('laura@example@.com')
    expect(subject).to_not match('laura@example.@com')
  end
end
