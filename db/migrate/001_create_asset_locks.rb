class CreateAssetLocks < ActiveRecord::Migration
  def self.up
    create_table :asset_locks do |t|
      t.integer :version
      t.timestamps
    end
    AssetLock.create(:version => 0)
  end

  def self.down
    drop_table :asset_locks
  end
end
