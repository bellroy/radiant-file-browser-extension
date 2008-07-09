include DirectoryArray

class Asset
  include Validatable
  attr_reader :parent_id, :version, :pathname, :id, :filename

  validates_each :filename, :logic => lambda {
    expanded_full_path = File.expand_path(File.join(absolute_path, @filename))
    if (@filename.slice(0,1) == '.') || @filename.match(/\/|\\/)
      errors.add(:filename, "contains illegal characters.")
    elsif expanded_full_path.index(absolute_path) != 0
      errors.add(:filename, "must not escape from the assets directory.")
    end
  }

  def initialize(asset)
    @filename = asset['name']
    @parent_id = asset['parent_id']
    @version = asset['version']
    @pathname = asset['pathname']
    @id = asset['id']
  end

  def self.find(id, version)
    if AssetLock.confirm_lock(version) and !id.blank? 
      asset_path = id2path(id)
      name = asset_path.basename
      parent_id = path2id(asset_path.parent)
      Asset.new('name' => name, 'parent_id' => parent_id, 'id' => id, 'pathname' => asset_path, 'version' => version)
    else
      empty_asset = Asset.new('version' => version)
      id.blank? ? empty_asset.errors.no = 3 : empty_asset.errors.no = 0
      empty_asset
    end    
  end

  def update(asset)
    @filename = asset['name']
    is_success = false
    if valid?
        if AssetLock.confirm_lock(@version) and !@pathname.nil?
          begin
            new_asset = Pathname.new(File.join(@pathname.parent, @filename))
            raise "exists" if new_asset.send("#{@pathname.ftype}?")
            @pathname.rename(new_asset)
            @pathname = Pathname.new(new_asset)
            @id = path2id(new_asset)
            AssetLock.new_lock_version
            is_success = true
          rescue RuntimeError => e
            e.message == 'exists' ? errors.add(:filename, 'already exists.') : errors.add(:filename, 'an unknown error occured.')
          end
        else
          errors.add(:filename, 'version mismatch.') 
        end
    end
    is_success
  end

  def destroy
    if AssetLock.confirm_lock(@version) and !@id.blank? 
      path = id2path(@id)
      return false if (path.to_s == absolute_path or path.to_s.index(absolute_path) != 0) #just in case
      if path.directory?
        FileUtils.rm_r path, :force => true
      elsif path.file?
        path.delete
      end
      AssetLock.new_lock_version         
    else
      errors.add(:filename, 'version mismatch.')
    end
  end

  protected

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

  class Errors

     CLIENT_ERRORS = [
       "The assets have been modified since it was last loaded hence the requested action could not be performed.",
       "The Asset name you are trying to create/edit already exists hence the requested action could not be performed.",
       "Asset name should not contain / \\ or a leading period.",
       "An error occured when trying to perform the requestion action. Possibly the id field is not provided.",
     ]

  end

end
