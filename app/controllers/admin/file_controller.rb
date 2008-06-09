class Admin::FileController < ApplicationController
  include DirectoryArray
  
  def index
    @assets = Pathname.new(FileBrowserExtension.asset_path)
    @asset_lock = AssetLock.lock_version
  end
  
  def new
    @assets = Pathname.new(FileBrowserExtension.asset_path)
    @parent_id = params[:parent_id]
    v = params[:v]
    if !confirm_lock(v) and !@parent_id.nil? and @parent_id.strip != ''
        flash[:error] = "The assets have been modified since it was last loaded. Please try again now."
        redirect_to files_path
    else
        if request.post? 
            new_type = params[:new_type]
            version = params[:version]   
            if new_type == 'UPLOAD'
               upload = params[:asset][:uploaded_data]
               file_asset = FileAsset.create(upload, @parent_id, version)
	       unless file_asset.success 		  
                  flash[:error] = file_asset.errors.to_s
	       end  
            elsif new_type == 'CREATE'
	       directory_name = params[:asset][:directory_name]
               directory_asset = DirectoryAsset.create(directory_name, @parent_id, version) 
               unless directory_asset.success
    	          flash[:error] = directory_asset.errors.to_s           
	       end
            end
            redirect_to files_path             
        end
        @asset_lock = AssetLock.lock_version
    end
  end
  
  def children
    if request.xhr?
      @asset_lock = params[:asset_lock]  
      if confirm_lock(@asset_lock)
         @id = params[:id]
         @assets = Pathname.new(FileBrowserExtension.asset_path) 
         @indent_level = params[:indent_level]
      else
         @error_message = "The assets have been modified since it was last loaded. Please <a href=''>reload</a> this page."
      end
      render :layout => false
    end
  end
  
  def remove
    id = params[:id]
    @asset_lock = AssetLock.lock_version
    if id.nil? or id == ''
       flash[:error] = "An error occured. Possibly the id field was not supplied." 
       redirect_to :action => 'index' 
    else
       v = params[:v]
       if !confirm_lock(v) 
           flash[:error] = "The assets have been modified since it was last loaded. Please try again now."
           redirect_to files_path
       else
          @assets = Pathname.new(FileBrowserExtension.asset_path) 
          @path = id2path(id)       
          if request.post?
     	     asset_version = params[:version]      
   	     file_dir = '' 
	     if @path.directory?
	     	 if DirectoryAsset.destroy(id, asset_version)    
		    flash[:notice] = "The directory was successfully removed from the assets."      
		 else
		    flash[:error] = "The assets have been modified since it was last loaded hence could not be deleted." 
		 end
	     elsif @path.file?
		 if FileAsset.destroy(id, asset_version)
		    flash[:notice] = "The file was successfully removed from the assets."      
		 else
		    flash[:error] = "The assets have been modified since it was last loaded hence could not be deleted." 
		 end
	     end
             redirect_to files_path 
          end
       end
    end
  end
  
  def edit
    id = params[:id]
    v = params[:v]
    if !confirm_lock(v) 
        flash[:error] = "The assets have been modified since it was last loaded. Please try again now."
        redirect_to files_path
    else
        if request.post?
          asset_version = params[:version]      
          asset = params[:file_name]          
          path = id2path(id)
          if path.file?	
               file_asset = FileAsset.update(id, asset, asset_version)	    
               if file_asset.success		       
                    flash[:notice] = file_asset.success
               else
                    flash[:error] = file_asset.errors.to_s
               end
          elsif path.directory?
               dir_asset = DirectoryAsset.update(id, asset, asset_version)
               if dir_asset.success
   	            flash[:notice] = dir_asset.success
               else
                    flash[:error] = dir_asset.errors.to_s
               end
          end               
          redirect_to files_path
        end
        @file_name = id2path(id).basename
        @asset_lock = AssetLock.lock_version
    end
  end  
  
  private

  def confirm_lock(version)
      return false if (version.nil? or version.to_s.strip == '')
      current_version = AssetLock.lock_version
      if version.to_s == current_version.to_s
        return true
      else
        return false
      end
  end

end
