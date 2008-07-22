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
        @id = path2id(new_dir)
        @pathname = new_dir
        @version = AssetLock.new_lock_version
      rescue Errors => e
        add_error(e)
      end
    end
    @id
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

end
