module DirectoryArray

  def get_directory_array(path)
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
    return asset_array.flatten
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
