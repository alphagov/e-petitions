class ParliamentConstituency < ActiveRecord::Base
  belongs_to :parliament
  belongs_to :constituency, primary_key: :external_id
end
