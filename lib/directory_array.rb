module DirectoryArray
#  attr_accessor  :directory_hash, :lock_version
  @@directory_hash = nil
  @@lock_version = nil  

  def get_directory_array(path)
    path_str = path.to_s
    @@directory_hash = {} if @@directory_hash.nil?
    @@lock_version = AssetLock.lock_version if @@lock_version.nil?
    return @@directory_hash[path_str] if ( @@directory_hash.has_key?(path_str) and AssetLock.confirm_lock(@@lock_version))
    asset_array = []
    asset_absolute_path = Pathname.new(FileBrowserExtension.asset_path.to_s)
    path.children.collect do |child|
      unless hidden?(child)
        if child.directory?
          asset_array << child.relative_path_from(asset_absolute_path)
          asset_array << get_directory_array(child)
        else  
          asset_array << child.relative_path_from(asset_absolute_path)
        end  
      end
    end
    asset_array.flatten!
    @@directory_hash[path_str] = asset_array
    @@lock_version = AssetLock.lock_version
    return asset_array
  end   

  def reset_directory_hash
    @@directory_hash = nil 
    @@lock_version = nil
  end

  def hidden?(path)
    path.realpath.basename.to_s =~ (/^\./)
  end    

  def id2path(id)
    asset_absolute_path = Pathname.new(FileBrowserExtension.asset_path.to_s)      
    asset_array = get_directory_array(asset_absolute_path)
    asset_absolute_path + asset_array[id.to_i]
  end

  def path2id(path)
    asset_absolute_path = Pathname.new(FileBrowserExtension.asset_path.to_s)         
    asset_array = get_directory_array(asset_absolute_path)     
    relative_path = Pathname.new(path).relative_path_from(asset_absolute_path)
    asset_array.index(relative_path)
  end

  def absolute_path(asset_relative_path=nil)
    asset_relative_path = nil if (!asset_relative_path.nil? and asset_relative_path.strip == '')
    asset_relative_path.nil? ? FileBrowserExtension.asset_path.to_s : File.join(FileBrowserExtension.asset_path.to_s, asset_relative_path)
  end

  def get_parent_id(id)
    path = id2path(id)    
    parent_path = path.parent
    return path2id(parent_path) unless parent_path == absolute_path
    return nil
  end

end
