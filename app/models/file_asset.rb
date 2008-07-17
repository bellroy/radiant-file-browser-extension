class FileAsset < Asset
  attr_reader :uploaded_data

  def initialize(asset)
    @uploaded_data = asset['uploaded_data']
    filename = @uploaded_data.blank? ? '' : @uploaded_data.original_filename
    super('name' => filename, 'parent_id' => asset['parent_id'], 'version' => asset['version'], 'new_type' => asset['new_type'])
  end

  def save
    if valid?
      begin
        raise Errors, :modified unless AssetLock.confirm_lock(@version)
        upload_location = upload_location(@parent_id)
        new_file = Pathname.new(File.join(upload_location, @asset_name))
        raise Errors, :modified unless AssetLock.confirm_lock(@version)
        File.open(new_file, 'wb') { |f| f.write(@uploaded_data.read) }
        @id = path2id(new_file)
        @pathname = new_file
        @version = AssetLock.new_lock_version
      rescue Errors => e
        add_error(e)
      end
    end
    @id
  end

end
