class AddFieldsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :agreed_to_terms, :boolean, default: false
    add_column :users, :partner, :string
    add_column :users, :one_associate, :boolean, default: false
    add_column :users, :two_associates, :boolean, default: false
  end
end
