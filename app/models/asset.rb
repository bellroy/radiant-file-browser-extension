include DirectoryArray

class Asset
  include Validatable
  attr_reader :parent_id, :version, :pathname, :id, :asset_name, :class_type

  validates_each :asset_name, :logic => lambda {
    expanded_full_path = File.expand_path(File.join(upload_location(@parent_id), @asset_name))  
    if @asset_name.blank?
      errors.add(:asset_name, Errors::CLIENT_ERRORS[:blankname])
    elsif (@asset_name.slice(0,1) == '.') || @asset_name.match(/\/|\\/)
      errors.add(:asset_name, Errors::CLIENT_ERRORS[:illegal_name])
    elsif expanded_full_path.index(absolute_path) != 0
      errors.add(:asset_name, Errors::CLIENT_ERRORS[:illegal_path])
    elsif Pathname.new(expanded_full_path).send("#{@class_type}?") 
      errors.add(:asset_name, Errors::CLIENT_ERRORS[:exists])    
    end
  }

  def initialize(asset)
    @asset_name = sanitize(asset['name'])
    @parent_id = asset['parent_id']
    @version = asset['version']
    @pathname = asset['pathname']
    @id = asset['id']
    @class_type = asset['new_type'].downcase
  end

  def self.find(*args)
    case args.first
      when :root then find_by_pathname(Pathname.new(absolute_path))
      else find_from_id(args[0], args[1])
    end
  end

  def self.find_from_id(id, version)
    if AssetLock.confirm_lock(version) and !id.blank? 
      asset_path = id2path(id)
      find_by_pathname(asset_path)
    else     
      empty_asset = Asset.new('name' => '', 'pathname' => nil, 'new_type' => '')
      id.blank? ? err_type = :blankid : err_type = :modified
      empty_asset.errors.add(:base, Errors::CLIENT_ERRORS[err_type])      
      empty_asset       
    end    
  end

  def update(asset)
    @asset_name = sanitize(asset['name'])
    if valid?
      begin
        raise Errors, :modified unless Asset.find(@id, @version).exists? 
        new_asset = Pathname.new(File.join(@pathname.parent, @asset_name))
        @pathname.rename(new_asset)
        @pathname = Pathname.new(new_asset)
        @id = path2id(new_asset)
        @version = AssetLock.new_lock_version
        @parent_id = get_parent_id(@id)
        return true
      rescue Errors => e
        add_error(e)
        return false 
      end
    end
  end

  def destroy
      path = id2path(@id)
      raise Errors, :illegal_path if (path.to_s == absolute_path or path.to_s.index(absolute_path) != 0) #just in case
      raise Errors, :modified unless Asset.find(@id, @version).exists? 
      if path.directory?
        FileUtils.rm_r path, :force => true
      elsif path.file?
        path.delete
      end
      AssetLock.new_lock_version         
      return true
    rescue Errors => e 
      add_error(e)
      return false
  end

  def exists?
    @pathname.nil? ? false : true
  end

  def sanitize(asset_name)
    asset_name.gsub! /[^\w\.\-]/, '_'
    return asset_name
  end

  def children
    @class_type == 'directory' ? @pathname.children.map { |c| Asset.find_by_pathname(c) }.compact : []
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

  def description
    return "Folder" if @class_type == 'directory'
    return image? ? "Image" : "File"
  end

  protected

  def self.find_by_pathname(asset_path)
    name = asset_path.basename.to_s
    return nil if name =~ (/^\./)  
    parent_id = path2id(asset_path.parent)
    class_type = asset_path.ftype  
    id = path2id(asset_path)  
    Asset.new('name' => name, 'parent_id' => parent_id, 'id' => id, 'pathname' => asset_path, 'version' => AssetLock.version, 'new_type' => class_type)
  end

  def absolute_path
    FileBrowserExtension.asset_path
  end

  def upload_location(parent_id)
    if parent_id.blank?
      upload_location = absolute_path        
    else
      upload_location = id2path(parent_id)        
    end
    return upload_location
  end

  def add_error(e)
    case e.message
      when :exists
        errors.add(:asset_name, Errors::CLIENT_ERRORS[e.message])
      when :modified
        errors.add(:base, Errors::CLIENT_ERRORS[e.message])
      when :illegal_path
        errors.add(:asset_name, Errors::CLIENT_ERRORS[e.message])
      when :illegal_name
        errors.add(:asset_name, Errors::CLIENT_ERRORS[e.message])
      else
        errors.add(:base, :unknown)
    end
  end

  class Errors < StandardError

    CLIENT_ERRORS = {
       :modified => "The Assets have been changed since it was last loaded hence the requested action could not be performed.",
       :exists => "already exists.",
       :illegal_name => "contains illegal characters.",
       :illegal_path => "must not escape from the assets directory.",
       :unknown => "An unknown error occured.",
       :blankid => "An error occured due to id field being blank.",
       :blankname => "field cannot be blank",
    }

  end

end
