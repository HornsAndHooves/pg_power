require 'spec_helper'

describe 'Indexes' do
  describe '#add_index' do
    it 'is built with the :where option' do
      index_options = { where: "active" }

      ActiveRecord::Migration.add_index(:pets, :name, index_options)

      PgSaurus::Explorer.index_exists?(:pets, :name, index_options).should be true
    end

    it 'allows indexes with expressions using functions' do
      ActiveRecord::Migration.add_index(:pets, ["lower(name)", "lower(color)"])

      PgSaurus::Explorer.index_exists?(:pets, ["lower(name)", "lower(color)"] ).should be true
    end

    it 'allows indexes with expressions using functions with multiple arguments' do
      ActiveRecord::Migration.add_index(:pets, "to_tsvector('english', name)", using: 'gin')

      PgSaurus::Explorer.index_exists?(:pets, "gin(to_tsvector('english', name))" ).should be true
    end

    it 'allows indexes with expressions using functions with multiple arguments as dumped' do
      ActiveRecord::Migration.add_index(:pets,
                                        "to_tsvector('english'::regconfig, name)",
                                        using: 'gin')

      PgSaurus::Explorer.index_exists?(:pets, "gin(to_tsvector('english', name))" ).should be true
    end

    # TODO support this canonical example
    it 'allows indexes with advanced expressions' do
      pending "Not sophisticated enough for this yet"
      ActiveRecord::Migration.add_index(:pets, ["(color || ' ' || name)"])

      PgSaurus::Explorer.index_exists?(:pets, ["(color || ' ' || name)"] ).should be true
    end

    it "allows partial indexes with expressions" do
      opts = { where: 'color IS NULL' }

      ActiveRecord::Migration.add_index(:pets, ['upper(name)', 'lower(color)'], opts)
      PgSaurus::Explorer.index_exists?(:pets, ['upper(name)', 'lower(color)'], opts).should be true
    end

    it "allows compound functional indexes for schema-qualified table names" do
      opts = { name: 'idx_demography_citizens_on_lower_last_name__lower_first_name' }
      args = [ "demography.citizens", ["lower(last_name)", "lower(first_name)"], opts ]

      ActiveRecord::Migration.add_index(*args)
      expect(PgSaurus::Explorer.index_exists?(*args)).to be_truthy
    end
  end

  describe '#remove_index' do
    it 'removes indexes with expressions using functions' do
      ActiveRecord::Migration.add_index(:pets, ["lower(name)", "lower(color)"])
      ActiveRecord::Migration.remove_index(:pets, ["lower(name)", "lower(color)"])

      PgSaurus::Explorer.index_exists?(:pets, ["lower(name)", "lower(color)"] ).should be false
    end

    it 'removes indexes built with the :where option' do

      index_options = { where: "active" }

      ActiveRecord::Migration.add_index(:pets, :name, index_options)
      ActiveRecord::Migration.remove_index(:pets, :name)

      PgSaurus::Explorer.index_exists?(:pets, :name, index_options).should be false
    end
  end

  describe '#index_exists' do
    it 'is true for simple options' do
      PgSaurus::Explorer.index_exists?('pets', :color).should be true
    end

    it 'supports table name as a symbol' do
      PgSaurus::Explorer.index_exists?(:pets, :color).should be true
    end

    it 'is true for simple options on a schema table' do
      PgSaurus::Explorer.index_exists?('demography.cities', :country_id).should be true
    end

    it 'is true for a valid set of options' do
      index_options = { unique: true, where: 'active'}
      PgSaurus::Explorer.index_exists?('demography.citizens',
                                      [:country_id, :user_id],
                                      index_options
                                     ).should be true
    end

    it 'is true for a valid set of options including name' do
      index_options = { unique: true,
                        where: 'active',
                        name: 'index_demography_citizens_on_country_id_and_user_id' }
      PgSaurus::Explorer.index_exists?('demography.citizens',
                                      [:country_id, :user_id],
                                      index_options
                                     ).should be true
    end

    it 'is false for a subset of valid options' do
      index_options = { where: 'active' }
      PgSaurus::Explorer.index_exists?('demography.citizens',
                                      [:country_id, :user_id],
                                      index_options
                                     ).should be false
    end

    it 'is false for invalid options' do
      index_options = { where: 'active' }
      PgSaurus::Explorer.index_exists?('demography.citizens',
                                      [:country_id],
                                      index_options
                                     ).should be false
    end

    it 'is true for a :where clause that includes boolean comparison' do
      index_options = { where: 'active' }
      ActiveRecord::Migration.add_index(:pets, :name, index_options)
      PgSaurus::Explorer.index_exists?(:pets, :name, index_options).should be true
    end

    it 'is true for a :where clause that includes text comparison' do
      index_options = { where: "color = 'black'" }
      ActiveRecord::Migration.add_index(:pets, :name, index_options)
      PgSaurus::Explorer.index_exists?(:pets, :name, index_options).should be true
    end

    it 'is true for a :where clause that includes NULL comparison' do
      index_options = { where: 'color IS NULL' }
      ActiveRecord::Migration.add_index(:pets, :name, index_options)
      PgSaurus::Explorer.index_exists?(:pets, :name, index_options).should be true
    end

    it 'is true for a :where clause that includes integer comparison' do
      index_options = { where: 'id = 4' }
      ActiveRecord::Migration.add_index(:pets, :name, index_options)
      PgSaurus::Explorer.index_exists?(:pets, :name, index_options).should be true
    end

    it 'is true for a compound :where clause' do
      index_options = { where: "id = 4 and color = 'black' and active" }
      ActiveRecord::Migration.add_index(:pets, :name, index_options)
      PgSaurus::Explorer.index_exists?(:pets, :name, index_options).should be true
    end

    it 'is true for concurrently created index' do
      index_options = { concurrently: true }
      PgSaurus::Explorer.index_exists?(:users, :email, index_options).should be true
    end

  end
end
