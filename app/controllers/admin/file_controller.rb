class Admin::FileController < ApplicationController
  include DirectoryArray
  
  def index
    @assets = Asset.find(:root)
    @asset_lock = AssetLock.lock_version
  end
  
  def new
    @asset_lock = AssetLock.lock_version
    @parent_id = params[:parent_id]
    params[:v].blank? ? lock_pass = true : lock_pass = AssetLock.confirm_lock(params[:v])
    if lock_pass
      if request.post?
        if params[:asset][:new_type] == 'Directory'
          @file = DirectoryAsset.new(params[:asset])
        else
          @file = FileAsset.new(params[:asset])
        end

        if @file.save
          redirect_to files_path
        else
          flash[:error] = @file.errors.full_messages.join(", ")          
          redirect_to files_path  if @file.errors.on(:modified)
        end
      end
    else
      flash[:error] = Asset::Errors::CLIENT_ERRORS[:modified]
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
    
    if @file.exists?
      if request.post?
        if @file.update(params[:asset])
          flash[:notice] = "#{@file.class_type.capitalize} has been successfully edited."  
          redirect_to files_path
        else
          flash[:error] = @file.errors.full_messages.join(", ")
          redirect_to files_path  if @file.errors.on(:modified)
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
      @id = params[:id]
      @assets = Asset.find(@id, @asset_lock)
      @indent_level = params[:indent_level].to_i
      @error_message = Asset::Errors::CLIENT_ERRORS[:modified] + " Please <a href=''>reload</a> this page." unless @assets.exists?                 
      render :layout => false
    end
  end       

end
