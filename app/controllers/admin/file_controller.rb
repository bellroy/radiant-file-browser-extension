class Admin::FileController < ApplicationController
  include DirectoryArray
  
  def index
    @assets = Pathname.new(FileBrowserExtension.asset_path)
  end
  
  def new
    @assets = Pathname.new(FileBrowserExtension.asset_path)
    @parent_id = params[:parent_id]
    if request.post? 
      new_type = params[:new_type]
      version = params[:version]   
      if new_type == 'UPLOAD'
        upload = params[:asset][:uploaded_data]
        file_asset = FileAsset.create(upload, @parent_id, version)
	if file_asset.success
 	   redirect_to files_path  		  
	else
           flash[:error] = file_asset.errors.to_s
	end  
      elsif new_type == 'CREATE'
	directory_name = params[:asset][:directory_name]
        directory_asset = DirectoryAsset.create(directory_name, @parent_id, version) 
        if directory_asset.success
           redirect_to files_path  
	else
	   flash[:error] = directory_asset.errors.to_s           
	end
      end             
    end
    @asset_lock = AssetLock.lock_version
  end
  
  def children
    if request.xhr?
      @id = params[:id]
      @assets = Pathname.new(FileBrowserExtension.asset_path)   
      @indent_level = params[:indent_level]
      render :layout => false
    end
  end
  
  def remove
    id = params[:id]
    redirect_to :action => 'index' if id.nil? or id == ''
    @assets = Pathname.new(FileBrowserExtension.asset_path) 
    @path = id2path(id)
    @asset_lock = AssetLock.lock_version
    if request.post?
      asset_version = params[:version]      
      file_dir = '' 
      if @path.directory?
          if DirectoryAsset.destroy(id, asset_version)    
              flash[:notice] = "The directory was successfully removed from the assets."      
              redirect_to :action => 'index' 
          else
              flash[:error] = "The assets have been modified since it was last loaded hence could not be deleted." 
          end
      elsif @path.file?
          if FileAsset.destroy(id, asset_version)
              flash[:notice] = "The file was successfully removed from the assets."      
              redirect_to :action => 'index'
          else
              flash[:error] = "The assets have been modified since it was last loaded hence could not be deleted." 
          end
      end
    end
  end
  
  def edit
    id = params[:id]
    if request.post?
      asset_version = params[:version]      
      asset = params[:file_name]          
      path = id2path(id)
      if path.file?	
           file_asset = FileAsset.update(id, asset, asset_version)	    
           if file_asset.success		       
                flash[:notice] = file_asset.success
                redirect_to :action => 'index'
           else
                flash[:error] = file_asset.errors.to_s
           end
      elsif path.directory?
           dir_asset = DirectoryAsset.update(id, asset, asset_version)
           if dir_asset.success
   	        flash[:notice] = dir_asset.success
                redirect_to :action => 'index'
           else
                flash[:error] = dir_asset.errors.to_s
           end
      end               
    end
    @file_name = id2path(id).basename
    @asset_lock = AssetLock.lock_version
  end  
  

end
