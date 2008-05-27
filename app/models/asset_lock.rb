class AssetLock < ActiveRecord::Base
  def self.get_version
    version = self.find_by_id(1)
    if !version.nil?
      return version
    else
      version = self.new(:version => 0)     
      version.save
      return version
    end
  end
end
