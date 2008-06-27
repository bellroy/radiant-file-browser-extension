include DirectoryArray

class Asset
  attr_reader :parent_id, :version 
  attr_accessor :errors, :success

  protected

  def self.get_absolute_path
	    FileBrowserExtension.asset_path
  end

  def self.get_upload_location(parent_id)
      if parent_id == '' or parent_id.nil?
        upload_location = self.get_absolute_path        
      else
        upload_location = id2path(parent_id)        
      end
      return upload_location
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

  def self.confirm_asset_validity_and_sanitize(asset)
    asset_absolute_path = self.get_absolute_path
    full_path = File.join(asset_absolute_path, asset)
    expand_full_path = File.expand_path(full_path)
    if (asset.slice(0,1) == '.') 
        return false
    elsif asset.match(/\/|\\/) 
        return false
    elsif expand_full_path.index(asset_absolute_path) != 0
        return false
    else
        asset.gsub! /[^\w\.\-]/, '_'
        return asset
    end
  end

end
