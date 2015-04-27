collection @petitions
attributes :id, :title, :description, :signature_count, :response, :state

node(:created_datetime) { |p| p.created_at.gmtime.iso8601 }
node(:closing_datetime) { |p| p.closed_at.present? ? p.closed_at.gmtime.iso8601 : nil }
node(:last_update_datetime) { |p| p.updated_at.gmtime.iso8601 }

glue :creator_signature do
  attributes :name => :creator_name
end
glue :department do
  attributes :name => :department_name
end
