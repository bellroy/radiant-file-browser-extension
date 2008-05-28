class AssetLock < ActiveRecord::Base
  def self.lock_version
    version.version
  end

  def self.new_lock_version
    version = self.version
    version.update_attribute(:version, version.version + 1)
    version.version
  end

  def self.version
    version = find(:first) || create(:version => 0)
  end
end
