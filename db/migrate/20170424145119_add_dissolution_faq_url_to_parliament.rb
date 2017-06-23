class AddDissolutionFaqUrlToParliament < ActiveRecord::Migration[4.2]
  def change
    add_column :parliaments, :dissolution_faq_url, :string, limit: 500
  end
end
