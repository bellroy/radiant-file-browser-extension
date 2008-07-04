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
          @pathname = new_file
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

  def extension 
    ext = @pathname.extname
    ext.slice(1, ext.length) if ext.slice(0,1) == '.'
  end

  def image?
    ext = extension.downcase
    return true if (ext == 'png' or ext == 'jpg' or ext == 'jpeg' or ext == 'bmp' or ext == 'gif')
    return false 
  end  

  def embed_tag
    if image?
      asset_path = FileAsset.public_asset_path
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
