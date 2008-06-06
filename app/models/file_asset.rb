class FileAsset < Asset
   attr_reader :upload, :filename 

   def initialize(upload, parent_id, version, name)
      @upload = upload
      @filename = Asset.confirm_asset_validity_and_sanitize(name)

      @parent_id = parent_id
      @version = version

      @errors = []
      @success = false
   end

   def save
      if Asset.confirm_lock(@version)           
           upload_location = Asset.get_upload_location(@parent_id)
           new_file = Pathname.new(File.join(upload_location, @filename))
           unless new_file.file?
              File.open(new_file, 'wb') { |f| f.write(@upload.read) }
              AssetLock.new_lock_version
              @success = true
           else
              @errors << "Filename already exists."
           end
      else
           @errors << "The assets have been modified since it was last loaded hence could not be created."
      end
   end

   def self.create(upload, parent_id, version)
      object = new(upload, parent_id, version, upload.original_filename)
      if object.filename
          unless object.version.nil? and object.version.nil?
             object.save
          else
             object.errors << "An error occured when trying to save."
          end
      else
          object.errors << "Filename cannot have characters like \\ / or a leading period."  
      end
      return object
   end

   def self.update(id, name, version)
      object = new(nil, nil, version, name)
      if object.filename
          unless object.version.nil? and object.version.nil?
              if self.confirm_lock(version)
                  path = id2path(id)
                  new_file = Pathname.new(File.join(self.get_absolute_path, name))
                  unless new_file.file?
                      path.rename(new_file)
                      object.success = "Filename has been sucessfully edited."
                      AssetLock.new_lock_version
                  else
                      object.errors << "Filename already exists."
                  end
             else
                  object.errors << "The assets have been modified since it was last loaded hence could not be edited." 
             end
         else
              object.errors << "An error occured when trying to save."
         end
      else
          object.errors << "Filename cannot have characters like \\ / or a leading period." 
      end
      return object
   end

   def self.destroy(id, version)
      ret_val = false
      if self.confirm_lock(version)
           path = id2path(id)
           path.delete
           ret_val = true
           AssetLock.new_lock_version         
      end
      return ret_val
   end

end
