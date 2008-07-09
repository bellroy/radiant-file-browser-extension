class DirectoryAsset < Asset

  def initialize(asset)    
    super(asset)
  end

  def save
    if valid?         
      upload_location = upload_location(@parent_id)
      new_dir = Pathname.new(File.join(upload_location, @filename))
      Dir.mkdir(new_dir)       
      @id = path2id(new_dir)
      @pathname = new_dir
      @version = AssetLock.new_lock_version
    end
  end

end
