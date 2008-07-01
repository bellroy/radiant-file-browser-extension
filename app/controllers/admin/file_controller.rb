class Admin::FileController < ApplicationController
  include DirectoryArray
  
  def index
    @assets = Pathname.new(FileBrowserExtension.asset_path)
    @asset_lock = AssetLock.lock_version
  end
  
  def new
    @asset_lock = AssetLock.lock_version
    if request.post?
      if params[:new_type] == 'Directory'
        @file = DirectoryAsset.new(params[:asset])
      else
        @file = FileAsset.new(params[:asset])
      end

      if @file.save
        redirect_to files_path
      else
        render new_asset_path
      end
    end
  end
  
  def remove
    @asset = Asset.find(params[:id], params[:version])
    @asset.destroy
    redirect_to files_path
  rescue ActiveRecord::RecordNotFound => error
    flash[:error] = error.message
    redirect_to :action => 'index'
  end
  
  def edit
    @file = Asset.find(params[:id], params[:v])
    
    unless @file.pathname.nil?
      if request.post?
        if @file.update(params[:file_name], params[:version])
          flash[:notice] = @file.success
        else
          flash[:error] = @file.errors.join(", ")
        end
    
        redirect_to files_path
      end
    else
       flash[:error] = @file.errors.join(", ")
       redirect_to files_path
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
    
    
  private

  # move this behaviour into the AssetLock class then use above directly or in the Asset objects
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
