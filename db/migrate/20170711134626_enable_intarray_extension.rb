class EnableIntarrayExtension < ActiveRecord::Migration[4.2]
  def change
    enable_extension "intarray"
  end
end
