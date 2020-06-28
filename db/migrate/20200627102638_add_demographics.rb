class AddDemographics < ActiveRecord::Migration[6.0]
  def change
    add_column :holders, :team_status, :integer
    add_index :holders, :team_status

    add_column :users, :under_18, :boolean
    add_index :users, :under_18

    add_column :users, :region, :integer
    add_index :users, :region

    add_column :users, :age, :integer
    add_index :users, :age

    add_column :users, :gender, :string
    add_index :users, :gender

    add_column :users, :first_peoples, :integer
    add_index :users, :first_peoples

    add_column :users, :disability, :integer
    add_index :users, :disability

    add_column :users, :education, :integer
    add_index :users, :education

    add_column :users, :employment, :integer
    add_index :users, :employment

    add_column :users, :postcode, :string
    add_index :users, :postcode
  end
end
