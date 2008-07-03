class FileAsset < Asset
  attr_reader :uploaded_data, :filename 

  def initialize(asset)
    @uploaded_data = asset['uploaded_data']
    @filename = Asset.confirm_asset_validity_and_sanitize(@uploaded_data.original_filename)
    @parent_id = asset['parent_id']
    @version = asset['version']
    @errors = Errors.new
    @success = false
  end

  def save
    if @filename
      if AssetLock.confirm_lock(@version)           
        upload_location = Asset.get_upload_location(@parent_id)
        new_file = Pathname.new(File.join(upload_location, @filename))
        unless new_file.file?
          File.open(new_file, 'wb') { |f| f.write(@uploaded_data.read) }
          @id = path2id(new_file)
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
