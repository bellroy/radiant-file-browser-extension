module Admin::FileHelper
  include Admin::NodeHelper
  include DirectoryArray

  def render_children(asset, locals = {})
    locals.reverse_merge!(:level => 0, :simple => false).merge!(:asset => asset)
    # TODO: should call render :partial => asset
    # ADVANTAGE: will allow directories and files to have separate partials
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
    
  def expanded?(asset)
    show_all? || (asset.root? if asset.respond_to?(:root?)) || expanded_rows_with_asset_lock.include?(asset.id)
  end

  def icon_for(asset)
    image_tag asset.icon, :alt => '', :class => 'icon'
  end
        
  def link_or_embed_field_for(asset)
    return "" unless asset.is_a?(FileAsset)
    template_code = asset.embed_tag
    %Q{
      <input type="text" value="#{h(template_code)}"
       style="width: 100%"
       onclick="this.focus();this.select()" />
     }
  end    
        
  def expander_for(asset)
    return nil if (asset.is_a?(FileAsset) or asset.children.empty?)
    image(expanded?(asset) ? "collapse" : "expand", 
          :class => "expander", :alt => 'toggle children', 
          :title => '')     
  end    
    
  def spinner_for(asset)
    image('spinner.gif', 
            :class => 'busy', :id => "busy-#{asset.id}", 
            :alt => "",  :title => "", 
            :style => 'display: none;')
  end    
      
  def link_to_new_file(asset)
    link_to image('add-child', :alt => 'add child'), new_file_path(:parent_id => asset.id, :v => asset.lock)  if asset.is_a?(DirectoryAsset)
  end
  
  def link_to_remove_file(asset)
    link_to image('remove', :alt => 'remove page'), '/admin/files/remove?id=' + asset.id.to_s + '&v=' + asset.lock.to_s unless (asset.respond_to?(:root?) and asset.root?)
  end

  def link_to_rename_file(asset)
     (asset.respond_to?(:root?) and asset.root?) ? asset.basename : "<a href='/admin/files/edit?id=#{asset.id}&v=#{asset.lock}'>#{asset.basename}</a>"
  end
  
end
