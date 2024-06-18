class ConstituenciesParliament < ActiveRecord::Base
  belongs_to :constituency
  belongs_to :parliament
end
