class DropTranslatedPetitionColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column :petitions, :action, :string, limit: 255
    remove_column :petitions, :background, :string, limit: 500
    remove_column :petitions, :additional_details, :text
  end
end
