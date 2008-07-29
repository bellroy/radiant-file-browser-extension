module Admin::FileHelper
  include Admin::NodeHelper
  include DirectoryArray

  def render_children(asset, locals = {})
    @current_asset = asset
    locals.reverse_merge!(:level => 0, :simple => false, :asset_lock => AssetLock.lock_version).merge!(:asset => asset)
    render :partial => 'children', :locals =>  locals
  end   
          
  def expanded_rows_with_asset_lock
    unless @expanded_rows
      @expanded_rows = case
      when (rows = cookies[:expanded_rows] and version = cookies[:version])         
        AssetLock.confirm_lock(version) ? rows.split(',').map { |x| Integer(x) rescue nil }.compact : []
      else
        []
      end
    end
    @expanded_rows
  end
    
  def expanded?
    show_all? || (@current_asset.root? if @current_asset.respond_to?(:root?)) || expanded_rows_with_asset_lock.include?(@current_asset.id)
  end

  def icon_for
    image_tag @current_asset.icon, :alt => '', :class => 'icon'
  end

  def asset_size
    "#{@current_asset.pathname.size} Bytes" if @current_asset.is_a?(FileAsset)
  end
        
  def link_or_embed_field_for
    return "" unless @current_asset.is_a?(FileAsset)
    template_code = @current_asset.embed_tag
    %Q{
      <input type="text" value="#{h(template_code)}"
       style="width: 100%"
       onclick="this.focus();this.select()" />
     }
  end    
        
  def expander
    return nil if (@current_asset.is_a?(FileAsset) or @current_asset.children.empty?)
    image(expanded? ? "collapse" : "expand", 
          :class => "expander", :alt => 'toggle children', 
          :title => '')     
  end    
    
  def spinner
    image('spinner.gif', 
            :class => 'busy', :id => "busy-#{@current_asset.id}", 
            :alt => "",  :title => "", 
            :style => 'display: none;')
  end    
      
  def link_to_new_file(asset_lock)
    link_to image('add-child', :alt => 'add child'), new_file_path(:parent_id => @current_asset.id, :v => asset_lock)  if @current_asset.is_a?(DirectoryAsset)
  end
  
  def link_to_remove_file(asset_lock)
    link_to image('remove', :alt => 'remove page'), '/admin/files/remove?id=' + @current_asset.id.to_s + '&v=' + asset_lock.to_s unless (@current_asset.respond_to?(:root?) and @current_asset.root?)
  end

  def link_to_rename_file(asset_lock)
     (@current_asset.respond_to?(:root?) and @current_asset.root?) ? @current_asset.pathname.basename : "<a href='/admin/files/edit?id=#{@current_asset.id}&v=#{asset_lock}'>#{@current_asset.pathname.basename}</a>"
  end
  
end
