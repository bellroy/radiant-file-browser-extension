class FileAsset < Asset
  attr_reader :uploaded_data

  def initialize(asset)
    @uploaded_data = asset['uploaded_data']
    super('name' => @uploaded_data.original_filename, 'parent_id' => asset['parent_id'], 'version' => asset['version'])
  end

  def save
    if valid?
      upload_location = upload_location(@parent_id)
      new_file = Pathname.new(File.join(upload_location, @filename))
      File.open(new_file, 'wb') { |f| f.write(@uploaded_data.read) }
      @id = path2id(new_file)
      @pathname = new_file
      @version = AssetLock.new_lock_version
    end
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
      return "<img src='#{asset_path}/#{@filename}' />"
    else
      return "<a href='#{asset_path}/#{@filename}'>#{@filename.capitalize}</a>"
    end
  end

  def self.public_asset_path
    asset_parent_path = Pathname.new(FileBrowserExtension.asset_parent_path)
    asset_root = Pathname.new(FileBrowserExtension.asset_path)
    asset_root.relative_path_from(asset_parent_path)     
  end

end
