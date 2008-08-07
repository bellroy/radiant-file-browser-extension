class FileAsset < Asset
  attr_reader :uploaded_data

  def initialize(asset)
    @uploaded_data = asset['uploaded_data']
    filename = @uploaded_data.blank? ? '' : @uploaded_data.original_filename
    @pathname = asset['pathname']
    @id = asset['id']
    filename = asset['name'] if self.exists?
    @asset_name = sanitize(filename)
    @parent_id = asset['parent_id']
    @version = asset['version']
  end

  def save
    if valid?
      begin
        raise Errors, :modified unless AssetLock.confirm_lock(@version)
        upload_location = upload_location(@parent_id)
        new_file = Pathname.new(File.join(upload_location, @asset_name))
        raise Errors, :modified unless AssetLock.confirm_lock(@version)
        File.open(new_file, 'wb') { |f| f.write(@uploaded_data.read) }
        reset_directory_hash
        @id = path2id(new_file)
        @pathname = new_file
        @version = AssetLock.new_lock_version
      rescue Errors => e
        add_error(e)
      end
    end
    @id
  end

  def destroy
      path = id2path(@id)
      raise Errors, :illegal_path if (path.to_s == absolute_path or path.to_s.index(absolute_path) != 0) 
      raise Errors, :modified unless Asset.find(@id, @version).exists? 
      path.delete
      reset_directory_hash
      AssetLock.new_lock_version         
      return true
    rescue Errors => e 
      add_error(e)
      return false
  end

  def extension 
    ext = @pathname.extname
    ext.slice(1, ext.length) if ext.slice(0,1) == '.'
  end

  def image?
    ext = extension.downcase unless extension.nil?
    return true if %w[png jpg jpeg bmp gif].include?(ext)
    return false 
  end  

  def embed_tag
    path = id2path(@id)    
    asset_path = path.relative_path_from(Pathname.new(FileBrowserExtension.asset_parent_path))
    if image?
      file_content = @pathname.read
      img = ImageSize.new(file_content, extension)    
      return "<img src='/#{asset_path}' width='#{img.get_width}px' height='#{img.get_height}px' />"
    else
      return "<a href='/#{asset_path}'>#{@asset_name.capitalize}</a>"
    end
  end

  def description    
    image? ? "Image" : "File"
  end

  def html_class
    "no-children"
  end

  def icon
    "admin/page.png"    
  end

end
