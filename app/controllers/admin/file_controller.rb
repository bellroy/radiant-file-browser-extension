class Admin::FileController < ApplicationController
  include DirectoryArray
  
  def index
    @assets = Pathname.new(FileBrowserExtension.asset_path)
    @asset_lock = AssetLock.lock_version
  end
  
  def new
    @asset_lock = AssetLock.lock_version
    @parent_id = params[:parent_id]
    params[:v].blank? ? lock_pass = true : lock_pass = AssetLock.confirm_lock(params[:v])
    if lock_pass
      if request.post?
        if params[:new_type] == 'Directory'
          @file = DirectoryAsset.new(params[:asset])
        else
          @file = FileAsset.new(params[:asset])
        end

        if @file.save
          redirect_to files_path
        else
          flash[:error] = @file.errors.full_messages.join(", ")          
          redirect_to files_path if @file.errors.no == 0
        end
      end
    else
      flash[:error] = Asset::Errors::CLIENT_ERRORS[0]
      redirect_to files_path
    end
  end
  
  def remove
    @asset = Asset.find(params[:id], params[:v])
    unless @asset.pathname.nil?
      if request.post?      
        if @asset.destroy
          flash[:notice] = "The asset was successfully removed."   
        else
          flash[:error] = @asset.errors.full_messages.join(", ")
        end
        redirect_to files_path
      end
    else
       flash[:error] = @asset.errors.full_messages.join(", ")
       redirect_to files_path
    end
  end
  
  def edit
    @file = Asset.find(params[:id], params[:v])
    
    unless @file.pathname.nil?
      if request.post?
        if @file.update(params[:asset])
          flash[:notice] = @file.success
          redirect_to files_path
        else
          flash[:error] = @file.errors.full_messages.join(", ")
          redirect_to files_path if @file.errors.no == 0
        end
   
      end
    else
       flash[:error] = @file.errors.full_messages.join(", ")
       redirect_to files_path
    end
  end
  
  def children
    if request.xhr?
      @asset_lock = params[:asset_lock]  
      if AssetLock.confirm_lock(@asset_lock)
         @id = params[:id]
         @assets = Pathname.new(FileBrowserExtension.asset_path) 
         @indent_level = params[:indent_level]
      else
         @error_message1 = Asset::Errors::CLIENT_ERRORS[0] + " Please <a href=''>reload</a> this page."
      end
      render :layout => false
    end
  end       

end
