require 'pathname'



def print_children(path, indent_level=0)
  path.children.each do |child|
    puts " " * indent_level + child.basename.to_s
    print_children(child, indent_level+1) if child.directory?
  end
end

print_children(assets)