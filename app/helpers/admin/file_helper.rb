module Admin::FileHelper
  include Admin::NodeHelper
  
  def print_path(path, indent_level=0)
    output = ''    
    if path.directory?
      output << print_dir_node(path, indent_level)
      output << print_children(path, indent_level)
    else
      output << print_file_node(path, indent_level)
    end
    output
  end
  
  def print_children(path, indent_level=0)
    path.children.collect do |child|
      print_path(child, indent_level+1) unless hidden?(child)
    end.to_s
  end
  
  private
    def print_dir_node(file, indent_level=0)
      html_class = "node level-#{indent_level}"
      %Q{
      <tr class="#{html_class}">
        <td class="directory" style="padding-left: #{padding_left(indent_level)}px">
          #{icon_for(file)}
          <span class="title">#{file.basename.to_s}</span>
        </td>
        <td class="type">Folder</td>
        <td class="size"></td>
        <td class="embed"></td>
      </tr>}
    end
    
    def print_file_node(file, indent_level=0)
      html_class = "node level-#{indent_level} no-children"
      %Q{
      <tr class="#{html_class}">
        <td class="file" style="padding-left: #{padding_left(indent_level)}px">
          #{icon_for(file)}
          <span class="title">#{file.basename.to_s}</span>
        </td>
        <td class="type">#{type_description_for(file)}</td>
        <td class="size">#{number_to_human_size(file.size)}</td>
        <td class="embed">#{link_or_embed_field_for(file)}</td>
      </tr>}
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
    
    def hidden?(path)
      path.realpath.basename.to_s =~ (/^\./)
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
  
end