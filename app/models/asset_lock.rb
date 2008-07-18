class AssetLock < ActiveRecord::Base
  def self.lock_version
    version.version
  end

  def self.new_lock_version
    version = self.version
    version.update_attribute(:version, version.version + 1)
    version.version
  end

  def self.confirm_lock(version)
    return false if (version.nil? or version.to_s.strip == '')
    current_version = AssetLock.lock_version
    if version.to_s == current_version.to_s
      return true
    else
      return false
    end
  end

  private

  def self.version
    version = find(:first) || create(:version => 0)
  end

end
