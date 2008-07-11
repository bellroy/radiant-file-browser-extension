class DirectoryAsset < Asset

  def initialize(asset)    
    super(asset)
  end

  def save
    if valid?      
      begin   
        upload_location = upload_location(@parent_id)
        new_dir = Pathname.new(File.join(upload_location, @asset_name))
        raise Errors, :modified unless AssetLock.confirm_lock(@version)
        Dir.mkdir(new_dir)       
        @id = path2id(new_dir)
        @pathname = new_dir
        @version = AssetLock.new_lock_version
      rescue Errors => e
        add_error(e)
      end
    end
    @id
  end

end
