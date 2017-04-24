class AddDissolutionFaqUrlToParliament < ActiveRecord::Migration
  def change
    add_column :parliaments, :dissolution_faq_url, :string, limit: 500
  end
end
