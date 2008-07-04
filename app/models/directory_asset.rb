class DirectoryAsset < Asset
  attr_reader :filename

  def initialize(asset)    
    @filename = Asset.confirm_asset_validity_and_sanitize(asset['directory_name'])
    @parent_id = asset['parent_id']
    @version = asset['version']
    @errors = Errors.new
    @success = false
  end

  def save
    if @filename
      if AssetLock.confirm_lock(@version)
        upload_location = Asset.get_upload_location(@parent_id)
        new_dir = Pathname.new(File.join(upload_location, @filename))
        unless new_dir.directory?
          Dir.mkdir(new_dir)       
          @id = path2id(new_dir)
          @pathname = new_dir
          @version = AssetLock.new_lock_version
          @success = true
        else
          @errors.no = 1
        end
      else
        @errors.no = 0
      end
    else
      @errors.no = 2
    end
    @success
  end

end
