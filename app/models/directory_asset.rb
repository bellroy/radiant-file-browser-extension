class DirectoryAsset < Asset

  def initialize(asset)
    @asset_name = sanitize(asset['name'])
    @parent_id = asset['parent_id']
    @version = asset['version']
    @pathname = asset['pathname']
    @id = asset['id']
  end

  def save
    if valid?      
      begin   
        upload_location = upload_location(@parent_id)
        new_dir = Pathname.new(File.join(upload_location, @asset_name))
        raise Errors, :modified unless AssetLock.confirm_lock(@version)
        Dir.mkdir(new_dir)       
        reset_directory_hash
        @id = path2id(new_dir)
        @pathname = new_dir
        @version = AssetLock.new_lock_version
      rescue Errors => e
        add_error(e)
      end
    end
    @id
  end
  
  def size
    # Don't report size for directories, it would return bogus size info (the 'directory file' on disk)
  end

  def destroy
      path = id2path(@id)
      raise Errors, :illegal_path if (path.to_s == absolute_path or path.to_s.index(absolute_path) != 0) 
      raise Errors, :modified unless Asset.find(@id, @version).exists? 
      FileUtils.rm_r path, :force => true
      reset_directory_hash
      AssetLock.new_lock_version         
      return true
    rescue Errors => e 
      add_error(e)
      return false
  end

  def description
    "Folder" 
  end

  def children
    @pathname.children.map { |c| (Asset.find_by_pathname(c) unless c.basename.to_s =~ (/^\./) ) }.compact
  end

  def html_class
    self.children.empty? ? "no-children" : "children-hidden" 
  end

  def root?
    @pathname.to_s == absolute_path
  end

  def icon
    "admin/directory.gif"
  end

end
