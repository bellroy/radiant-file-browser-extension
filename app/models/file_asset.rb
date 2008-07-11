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

  def extension 
    ext = @pathname.extname
    ext.slice(1, ext.length) if ext.slice(0,1) == '.'
  end

  def image?
    ext = extension.downcase
    return true if %w[png jpg jpeg bmp gif].include?(ext)
    return false 
  end  

  def embed_tag
    asset_path = FileAsset.public_asset_path
    if image?
      return "<img src='#{asset_path}/#{@asset_name}' />"
    else
      return "<a href='#{asset_path}/#{@asset_name}'>#{@asset_name.capitalize}</a>"
    end
  end

  def self.public_asset_path
    asset_parent_path = Pathname.new(FileBrowserExtension.asset_parent_path)
    asset_root = Pathname.new(FileBrowserExtension.asset_path)
    asset_root.relative_path_from(asset_parent_path)     
  end

end
