module AnonymousSubclass
  # load file as an anonymous object inherited from superklass
  def self.create_object(filename, superklass)
    path = File.expand_path(filename)
    v = Class.new(superklass)
    v.const_set('FILENAME', path)    
    v.module_eval(IO.read(path), path)
    v.new
  end
end # module AnonymousSubclass
