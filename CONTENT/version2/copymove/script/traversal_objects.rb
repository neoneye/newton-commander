class TOVisitor
  def visit_file(obj)
  end

  def visit_dir(obj)
  end

  def visit_dir_pre(obj)
  end

  def visit_dir_post(obj)
  end

  def visit_link(obj)
  end

  #def visit_other(obj)
  #end
end


class TOBase
  def initialize
    @source_path = nil
    @target_dir = nil
    @target_name = nil
  end
  attr_accessor :source_path, :target_dir, :target_name
  
  def accept(visitor)
  end
end

class TOFile < TOBase
  def accept(visitor)
    visitor.visit_file(self)
  end
end

class TODir < TOBase
  def accept(visitor)
    visitor.visit_dir(self)
  end
end

class TODirPre < TOBase
  def accept(visitor)
    visitor.visit_dir_pre(self)
  end
end

class TODirPost < TOBase
  def initialize
    @delete_source_path = false
  end
  attr_accessor :delete_source_path
  
  def accept(visitor)
    visitor.visit_dir_post(self)
  end
end

class TOLink < TOBase
  def accept(visitor)
    visitor.visit_link(self)
  end
end

#class TOOther < TOBase
#  def accept(visitor)
#    visitor.visit_other(self)
#  end
#end

