class Dir

  #
  # invoke callback for all items in a dir
  # supplies the absolute_path as an argument to the callback
  #
  def self.chdir_glob_all(path_to_dir, &block)
    Dir.chdir(path_to_dir) do
      Dir.glob('*').each do |name|
        fullpath = File.expand_path(name)
        block.call(fullpath)
      end
    end
    nil
  end
end

