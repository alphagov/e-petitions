require 'factory_girl'

Factory.define :admin_user do |u|
  u.sequence(:email) {|n| "admin#{n}@example.com" }
  u.password              "SheBang22!"
  u.password_confirmation "SheBang22!"
  u.sequence(:first_name) {|n| "AdminUser#{n}" }
  u.sequence(:last_name) {|n| "AdminUser#{n}" }
  u.role "admin"
  u.force_password_reset  false
end

Factory.define :sysadmin_user, :parent => :admin_user do |u|
  u.role "sysadmin"
end

Factory.define :threshold_user, :parent => :admin_user do |u|
  u.role "threshold"
end

Factory.define :department do |d|
  d.sequence(:name) {|n| "Department #{n}" }
  d.website_url "http://department.gov.uk"
end

Factory.define :petition do |p|
  p.sequence(:title) {|n| "Petition #{n}" }
  p.description "Petition description"
  p.association :department 
  p.creator_signature  { |cs| cs.association(:signature, :state => Signature::VALIDATED_STATE) }
end

Factory.define :pending_petition, :parent => :petition do |p|
  p.state  Petition::PENDING_STATE
  p.creator_signature  { |cs| cs.association(:signature, :state => Signature::PENDING_STATE) }
end

Factory.define :validated_petition, :parent => :petition do |p|
  p.state  Petition::VALIDATED_STATE
end

Factory.define :open_petition, :parent => :petition do |p|
  p.state      Petition::OPEN_STATE
  p.open_at    Time.zone.now
  p.closed_at  1.day.from_now
end

Factory.define :closed_petition, :parent => :petition do |p|
  p.state      Petition::OPEN_STATE
  p.open_at    10.days.ago
  p.closed_at  1.day.ago
end

Factory.define :rejected_petition, :parent => :petition do |p|
  p.state  Petition::REJECTED_STATE
  p.rejection_code "Just do not like"
end

Factory.define :hidden_petition, :parent => :petition do |p|
  p.state      Petition::HIDDEN_STATE
end

Factory.define :signature do |s|
  s.sequence(:name) {|n| "Jo Public #{n}" }
  s.sequence(:email) {|n| "jo#{n}@public.com" }
  s.email_confirmation  {|sig| sig.email }
  s.address             "10 Downing St"
  s.town                "London"
  s.postcode            "SW1A 2"
  s.country             "United Kingdom"
  s.humanity             true
  s.uk_citizenship       '1'
  s.notify_by_email      '1'
  s.terms_and_conditions '1'
  s.state                Signature::VALIDATED_STATE
end

Factory.define :pending_signature, :parent => :signature do |s|
  s.state      Signature::PENDING_STATE
end

Factory.define :validated_signature, :parent => :signature do |s|
  s.state      Signature::VALIDATED_STATE
end

Factory.define :system_setting do |s|
  s.sequence(:key)  {|n| "key#{n}"}
end
