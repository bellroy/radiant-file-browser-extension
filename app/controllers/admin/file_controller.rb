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
      if @parent_id == '' or @parent_id.nil?
        upload_location = FileBrowserExtension.asset_path        
      else
        upload_location = id2path(@parent_id)        
      end
   
      if new_type == 'UPLOAD' && (upload = params[:asset][:uploaded_data])
        new_file = Pathname.new(File.join(upload_location, upload.original_filename))
        unless new_file.file?
          File.open(new_file, 'wb') { |f| f.write(upload.read) }
          AssetLock.new_lock_version
        else
          flash[:error] = "Filename already exists."
        end
        redirect_to files_path      
      elsif new_type == 'CREATE'
        directory_name = params[:asset][:directory_name]
        new_dir = File.join(upload_location, directory_name)        
        directory_path = Pathname.new(new_dir)
        unless directory_path.directory?
          Dir.mkdir(directory_path) 
          AssetLock.new_lock_version
        else
          flash[:error] = "Directory already exists."
        end
        redirect_to files_path         
      end      
    end
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
      if confirm_version(asset_version)
          file_dir = '' 
          if @path.directory?
            file_dir = 'directory'         
            @path.rmdir
          elsif @path.file?
            file_dir = 'file'         
            @path.delete
          end
          flash[:notice] = "The "+file_dir+" was successfully removed from the assets."
          AssetLock.new_lock_version         
          redirect_to :action => 'index'
      else
          flash[:error] = "The assets have been modified since it was last loaded hence could not be deleted."        
      end  
    end
  end
  
  def edit
    id = params[:id]
    if request.post?
      asset_version = params[:version]      
      if confirm_version(asset_version)          
          file_path = Pathname.new(File.join(FileBrowserExtension.asset_path, params[:file_name])) 
          path = id2path(id)
          if path.file?
            if !file_path.file?
                path.rename(file_path)
                AssetLock.new_lock_version   
                flash[:notice] = "Filename has been sucessfully edited."
            else
                flash[:error] = "Filename already exists."  
            end
          elsif path.directory?
            if !file_path.directory?
                path.rename(file_path)
                AssetLock.new_lock_version 
                flash[:notice] = "Directory has been sucessfully edited."
            else
                flash[:error] = "Directory already exists."              
            end
          end
          redirect_to :action => 'index'                 
      else          
          @file_name = id2path(id).basename
          @asset_lock = AssetLock.lock_version         
          flash[:error] = "The assets have been modified since it was last loaded hence could not be edited."
      end
    else
      @file_name = id2path(id).basename
      @asset_lock = AssetLock.lock_version
    end
  end  
  
  private
  
  def confirm_version(version)
    current_version = AssetLock.lock_version
    if version.to_i == current_version.to_i
      return true
    else
      return false
    end
  end
  
end
