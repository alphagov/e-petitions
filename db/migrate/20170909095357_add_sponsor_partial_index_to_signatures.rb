class AddSponsorPartialIndexToSignatures < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:signatures, name: "index_signatures_on_petition_id_where_sponsor_is_true")
      add_index :signatures, :petition_id,
        where: "sponsor = 't'", algorithm: :concurrently,
        name: "index_signatures_on_petition_id_where_sponsor_is_true"
    end
  end

  def down
    if index_exists?(:signatures, name: "index_signatures_on_petition_id_where_sponsor_is_true")
      remove_index :signatures, name: "index_signatures_on_petition_id_where_sponsor_is_true"
    end
  end

  private

  def index_exists?(table, names_or_options)
    if names_or_options.is_a?(Hash)
      select_value("SELECT to_regclass('#{names_or_options[:name]}')")
    else
      select_value("SELECT to_regclass('index_#{table}_on_#{Array(names_or_options).join('_and_')}')")
    end
  end
end
