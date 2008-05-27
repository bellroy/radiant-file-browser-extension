module Admin::FileHelper
  include Admin::NodeHelper
  include DirectoryArray
  
  def print_path(path, indent_level=0, simple=false)
    output = ''    
    if path.directory?
      output << print_dir_node(path, indent_level, false, simple)
    else
      output << print_file_node(path, indent_level, simple)
    end
    output
  end
  
  def render_children(path, id='', indent_level=0, show_parent_dir=false, simple=false)
    if path.directory?
      @asset_absolute_path = path    
      asset_array = get_directory_array(path)
      if id != ''
        path = path + asset_array[id.to_i].to_s
        path = Pathname.new(path)
      end
      print_children(path, indent_level.to_i, show_parent_dir, simple)
    else
      print_file_node(path, 0, simple) 
    end
  end
  
  def print_children(path, indent_level=0, show_parent_dir=false, simple=false)  
    output = ''    
    output << print_dir_node(path, 0, true, simple) if show_parent_dir == true 
    path.children.collect do |child|
      output << print_path(child, indent_level+1, simple) unless hidden?(child)
    end
    output
  end
  
  def asset_to_array(path)
    asset_array = get_directory_array(path)
    output = '['
    asset_array.each do |a|
      output << '"' + a + '"'
      output << ","      
    end
    output.chomp!(',')
    output << ']'
  end
  
  private
    def print_dir_node(file, indent_level=0, dont_expand=false, simple=false)
      file_id = path2id(file)
      html_class = "node level-#{indent_level} children-hidden"
      %Q{
      <tr class="#{html_class}" id = "page-#{file_id}" >
        <td class="directory" style="padding-left: #{padding_left(indent_level)}px">
          <span class="w1">
          #{expander dont_expand}         
          #{icon_for(file)}
          <span class="title"><a href='/admin/files/edit?id=#{file_id}'>#{file.basename.to_s}</a></span>
          #{spinner(file_id)}          
          </span>
        </td>
        <td class="type">Folder</td>
       } + 
        if !simple 
          %Q{ 
          <td class="size"></td>
          <td class="embed"></td>
          <td class="add-child">#{link_to_new_file(file_id)}</td>
          <td class="remove">#{link_to_remove_file(file_id)}</td> 
          </tr>} 
        else
          ''
        end
    end
    
    def print_file_node(file, indent_level=0, simple=false)
      file_id = path2id(file)      
      html_class = "node level-#{indent_level} no-children"
      %Q{
      <tr class="#{html_class}" id = "page-#{file_id}">
        <td class="file" style="padding-left: #{padding_left(indent_level)}px">
          #{icon_for(file)}
          <span class="title"><a href='/admin/files/edit?id=#{file_id}'>#{file.basename.to_s}</a></span>
        </td>
        <td class="type">#{type_description_for(file)}</td>
        } + 
        if !simple 
          %Q{           
          <td class="size">#{number_to_human_size(file.size)}</td>
          <td class="embed">#{link_or_embed_field_for(file)}</td>
          <td class="add-child"></td>
          <td class="remove">#{link_to_remove_file(file_id)}</td>        
          </tr>}
        else
          ''
        end
    end
            
    def icon_for(path)
      image_tag 'admin/page.png', :alt => '', :class => 'icon'
    end

    def type_description_for(path)
      ext(path).upcase + (image?(path) ? ' Image' : ' File')
    end
    
    def ext(path)
      path.extname.gsub('.','')
    end
    
    Image_extensions = %w[png gif jpg jpeg]
    def image?(path)
      Image_extensions.include?(ext(path))
    end
        
    def link_or_embed_field_for(path)
      template_code = (image?(path) ? embed_code_for(path) : link_code_for(path))
      %Q{
        <input type="text" value="#{h(template_code)}"
         style="width: 100%"
         onclick="this.focus();this.select()" />
      }
    end
    
    def embed_code_for(path)
      %Q{<r:img src="#{http_path(path)}" />}
    end
    
    def link_code_for(path)
      %Q{<r:asset_link href="#{http_path(path)}">#{path.basename} (#{type_description_for(path)}, #{number_to_human_size(path.size)})</r:asset_link>}
    end
    
    # Returns the HTTP-Accessible path for the given absolute filesystem path
    def http_path(path)
      http_root = Pathname.new(FileBrowserExtension.asset_path)
      path.relative_path_from(http_root)
    end
      
    def add_children_button_for(path)
      link_to(image_tag('admin/add-child.png', :alt => 'Add Child'), new_file_path)
    end
    
    # def remove_button_for(path)
    #   link_to(image_tag('admin/remove.png', :alt => 'Remove File'), remove_file_path(:path => path.to_s))
    # end    
    
    #added by Sanath
    def expander(dont_expand)
      image(dont_expand ? "collapse" : "expand", 
            :class => "expander", :alt => 'toggle children', 
            :title => '')      
    end    
    
    def spinner(file_id)
      image('spinner.gif', 
              :class => 'busy', :id => "busy-#{file_id}", 
              :alt => "",  :title => "", 
              :style => 'display: none;')
    end    
      
    def link_to_new_file(file_id)
      link_to image('add-child', :alt => 'add child'), new_file_path(:parent_id => file_id)
    end
  
    def link_to_remove_file(file_id)
      link_to image('remove', :alt => 'remove page'), '/admin/files/remove?id=' + file_id.to_s
    end
  
end