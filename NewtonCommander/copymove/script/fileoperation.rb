require 'traversal_objects'
require 'pty'
require 'expect'


# depends on: http://flori.github.com/json/
# gem install json
require 'json'


class FileOperationCancelError < StandardError  
end

class FileOperation < TOVisitor
  def initialize
    @obj_queue = []
    @exclude_file_patterns = []
    @exclude_dir_patterns = []
  end
  
  attr_accessor :exclude_file_patterns
  attr_accessor :exclude_dir_patterns

=begin  
  def obtain_traversal_objects_for_dir(source_dir)
    unless File.exist?(source_dir)
      raise "source_dir doesn't exist. #{source_dir}"
    end
    names = []
    Dir.chdir(source_dir) { names = Dir.glob('*') }

    traversal_objects = []
    
    names.each do |name|
      source_path = File.join(source_dir, name)
        
      if File.symlink?(source_path)
        obj = TOLink.new
        obj.source_path = source_path
        traversal_objects << obj
      elsif File.file?(source_path)
        obj = TOFile.new
        obj.source_path = source_path
        traversal_objects << obj
      elsif File.directory?(source_path)
        obj = TODir.new
        obj.source_path = source_path
        traversal_objects << obj
      else
        raise "unknown file type at path #{source_path}"
      end
      
    end
    
    traversal_objects
  end
  
  def assign_target_path(objs, target_dir)
    objs.each do |obj|
      obj.target_dir = target_dir
      obj.target_name = File.basename(obj.source_path)
    end
  end
  
  def visit_file(obj)
#    p obj
    block = @visit_block                   
    
    source_path = obj.source_path
    target_path = File.join(obj.target_dir, obj.target_name)
    name = File.basename(obj.source_path)

    @exclude_file_patterns.each do |pattern|
      if pattern =~ name 
        #puts "excluding file #{name} because it matches pattern #{pattern}"
        return
      end
    end

    perform_copymove_file(source_path, target_path, name, &block)
  end

  def visit_dir(obj)
#    p obj
    block = @visit_block
    name = File.basename(obj.source_path)
    
    dir_pre = TODirPre.new
    dir_pre.source_path = obj.source_path
    dir_pre.target_dir = obj.target_dir
    dir_pre.target_name = obj.target_name

    dir_post = TODirPost.new
    dir_post.source_path = obj.source_path
    dir_post.target_dir = obj.target_dir
    dir_post.target_name = obj.target_name



    source_path = obj.source_path
    target_path = File.join(obj.target_dir, obj.target_name)
    name = File.basename(obj.source_path)

    @exclude_dir_patterns.each do |pattern|
      if pattern =~ name 
        #puts "excluding dir #{name} because it matches pattern #{pattern}"
        return
      end
    end
    
    operation = perform_copymove_dir(source_path, target_path, name, dir_pre, dir_post, &block)
    
    if operation != :skip
      objs_in_dir = obtain_traversal_objects_for_dir(obj.source_path)
      assign_target_path(objs_in_dir, File.join(obj.target_dir, obj.target_name))

      objs = []
      objs << dir_pre
      objs += objs_in_dir
      objs << dir_post
      @obj_queue = objs + @obj_queue
    end
  end

  def visit_dir_pre(obj)
    #source_path = obj.source_path
    #target_path = File.join(obj.target_dir, obj.target_name)
    #name = File.basename(obj.source_path)
    #perform_copymove_dir(source_path, target_path, name, &block)
  end

  def visit_dir_post(obj)
    if obj.delete_source_path
      #puts "deleting dir: #{obj.source_path}"
      FileUtils.rm_rf(obj.source_path)
    end
  end

  def visit_link(obj)
    readlink = File.readlink(obj.source_path)
    target_path = File.join(obj.target_dir, obj.target_name)
    Dir.chdir(obj.target_dir) do
      FileUtils.ln_s(readlink, obj.target_name, :force => true)
      #system("ls -la")
    end
    #p 'link'
  end

  def ruby_perform_copymove(&block)
    @visit_block = block
    objs = obtain_traversal_objects_for_dir('source')
#    p objs
    assign_target_path(objs, 'target')
#    p objs

    @obj_queue = objs
    while @obj_queue.count >= 1
      obj = @obj_queue.shift
      begin
        obj.accept(self)
      rescue FileOperationCancelError => e
        #puts "operation was cancelled by user"
        @obj_queue = []
      end
    end
    
    @visit_block = nil
  end
=end

  def create_config_json(operation)
    config_path = File.join(Dir.pwd, 'config.json')
    source_dir = File.join(Dir.pwd, 'source')
    target_dir = File.join(Dir.pwd, 'target')

    unless File.exist?(source_dir)
      raise "source_dir doesn't exist. #{source_dir}"
    end

    unless File.exist?(target_dir)
      raise "target_dir doesn't exist. #{target_dir}"
    end
    
    unless @exclude_file_patterns.kind_of?(Array)
      raise "exclude_file_patterns must be an array"
    end
    
    unless @exclude_dir_patterns.kind_of?(Array)
      raise "exclude_dir_patterns must be an array"
    end
    
    copy_or_move = nil
    if operation == :copy
      copy_or_move = 'copy'
    elsif operation == :move
      copy_or_move = 'move'
    else
      raise "unknown operation #{operation}, only :copy and :move are allowed!"
    end
    
    names = []
    Dir.chdir(source_dir) { names = Dir.glob('*') }

    config = {}
    config['operation'] = copy_or_move
    config['source'] = source_dir
    config['target'] = target_dir
    config['names'] = names
    config['exclude_file_patterns'] = @exclude_file_patterns
    config['exclude_dir_patterns'] = @exclude_dir_patterns
    File.open(config_path, 'w+') {|f| f.write(JSON.generate(config)) }
  end

  def objc_perform_copymove(operation, &block)
    unless global_variables.grep('$worker_path')
      raise 'expected $rakefile_dir to be a global variable set by the rakefile, but there is no such variable'
    end
    path = $worker_path
    unless File.file?(path)
      raise "cannot find worker process: #{path}, you must build the xcode project and set worker_path to point at the executable"
    end
    
    create_config_json(operation)

    ENV['COPYMOVE_CONFIG_JSON'] = File.join(Dir.pwd, 'config.json')
    command = path + ' json "$COPYMOVE_CONFIG_JSON" 2>&1 | tee copymove_output.txt'
    PTY.spawn(command) do |r_f, w_f, pid|
      w_f.sync = true
      $expect_verbose = false
      
      # wait for the worker to validate that the json file is correct
      r_f.expect(/PROMPT> /) do |output|
        s = output[0]
        if s =~ /STATUS=OK/
          # status is OK
        elsif s =~ /STATUS=ERROR_(\d+)/
          error_code = $1
          p s
          raise "status_error in worker! error_code: #{error_code}"
        else
          p s
          raise "unknown_error in worker!"
        end
      end
      

      prompt_command = "start\n"
      while prompt_command
        
        # puts "command: #{prompt_command}"
        w_f.print prompt_command
        prompt_command = nil
        
        r_f.expect(/PROMPT> /) do |output|
          s = output[0]
          # p s

          ##############################################
          if s =~ /FILENAMECOLLISION/
            # p 'file name collision'
            # prompt_command = "skip\n"
            

            s =~ /source_path: (.*?)[\r\n]/
            source_name = $1

            s =~ /target_path: (.*?)[\r\n]/
            target_name = $1

            name = File.basename(target_name)

            collision_type = :file
            
            # p source_name, target_name, name

            # ask the user what to do with file
            mixed = block.call(source_name, target_name, name, collision_type)
            # p operation

            operation = nil
            argument1 = nil
            if mixed.kind_of?(Array)
              raise "expected array to have 2 arguments. #{mixed}" if mixed.size != 2
              operation = mixed[0]
              argument1 = mixed[1]
            elsif mixed.kind_of?(Symbol)
              operation = mixed
            else
              raise "unknown operation #{mixed}"
            end

            if operation == :rename_source
              raise "argument1 must not be nil" unless argument1
              prompt_command = "rename_source #{argument1}\n"
            elsif operation == :rename_target
              raise "argument1 must not be nil" unless argument1
              prompt_command = "rename_target #{argument1}\n"
            elsif operation == :skip
              prompt_command = "skip\n"
            elsif operation == :stop
              prompt_command = "stop\n"
            elsif operation == :retry
              prompt_command = "retry\n"
            elsif operation == :replace
              prompt_command = "replace\n"
            elsif operation == :append
              prompt_command = "append\n"
            else
              raise "unknown operation: #{operation}"
            end
          end

          ##############################################
          if s =~ /DIRECTORYNAMECOLLISION/
            # p 'directory name collision'
            # prompt_command = "skip\n"
            

            s =~ /source_path: (.*?)[\r\n]/
            source_name = $1

            s =~ /target_path: (.*?)[\r\n]/
            target_name = $1

            name = File.basename(target_name)

            collision_type = :dir
            
            # p source_name, target_name, name
            

            # ask the user what to do with directory
            mixed = block.call(source_name, target_name, name, collision_type)
            # p operation
            
            operation = nil
            argument1 = nil
            if mixed.kind_of?(Array)
              raise "expected array to have 2 arguments. #{mixed}" if mixed.size != 2
              operation = mixed[0]
              argument1 = mixed[1]
            elsif mixed.kind_of?(Symbol)
              operation = mixed
            else
              raise "unknown operation #{mixed}"
            end

            if operation == :rename_source
              raise "argument1 must not be nil" unless argument1
              prompt_command = "rename_source #{argument1}\n"
            elsif operation == :rename_target
              raise "argument1 must not be nil" unless argument1
              prompt_command = "rename_target #{argument1}\n"
            elsif operation == :skip
              prompt_command = "skip\n"
            elsif operation == :stop
              prompt_command = "stop\n"
            elsif operation == :retry
              prompt_command = "retry\n"
            elsif operation == :replace
              prompt_command = "replace\n"
            elsif operation == :merge
              prompt_command = "merge\n"
            else
              raise "unknown operation: #{operation}"
            end
          end
          ##############################################

        end
      end

    end
    
    # exit
    
  end

  def perform_copymove(operation, &block)
    # TODO: get the objc copy move code working
    # ruby_perform_copymove(&block)
    objc_perform_copymove(operation, &block)
  end

  
  def perform_copy(&block)
    perform_copymove(:copy, &block)
  end

  def perform_move(&block)
    perform_copymove(:move, &block)
  end


=begin  
  def perform_copymove_file(source_name, target_name, name, &block)
    
    unless File.file?(source_name)
      raise "In perform_copymove_file method the source_name must point to a file. #{source_name}"
    end
    
    operation = :skip
    begin
      @rename_new = nil
      @rename_old = nil
      @append_mode = false

      name_collision = is_name_taken(target_name)
    
      # ask the user what to do with file
      operation = block.call(source_name, target_name, name, name_collision)
      
      if operation == :stop
        raise FileOperationCancelError.new
      end
    
    end while operation == :retry

    n = 0
    n += 1 if @rename_new
    n += 1 if @rename_old
    raise "ERROR: only 1 option is allowed" if n > 1
      
    if name_collision
      if @rename_new
        path = @rename_new
        if FileTest.exist?(path)
          raise "ERROR: the name used when renaming must not be a file that already exist"
        end
        target_name = path
        name_collision = false
      end
    
      if @rename_old
        path = @rename_old
        if FileTest.exist?(path)
          raise "ERROR: the name used when renaming must not be a file that already exist"
        end
        FileUtils.mv(target_name, path)
        name_collision = false
      end
    
    end

    if operation == :copy
      if @append_mode
        File.append(source_name, target_name)
      else
        if name_collision 
          FileUtils.rm_rf(target_name)
        end
        FileUtils.cp_r(source_name, target_name, :preserve => true)
      end
    elsif operation == :move
      if @append_mode
        File.append(source_name, target_name)
        FileUtils.rm(source_name)
      else
        if name_collision 
          FileUtils.rm_rf(target_name)
        end
        FileUtils.mv(source_name, target_name)
      end
    elsif operation == :skip
      # do nothing
    else
      raise "ERROR: unknown operation #{operation} in copymove code"
    end

  end

  def perform_copymove_dir(source_name, target_name, name, dir_pre, dir_post, &block)
    
    unless File.directory?(source_name)
      raise "In perform_copymove_dir method the source_name must point to a directory. #{source_name}"
    end
    
    operation = :skip
    begin
      @rename_new = nil
      @rename_old = nil
      @append_mode = false

      name_collision = is_name_taken(target_name)
    
      # ask the user what to do with dir
      operation = block.call(source_name, target_name, name, name_collision)

      if operation == :stop
        raise FileOperationCancelError.new
      end
    
    end while operation == :retry

    n = 0
    n += 1 if @rename_new
    n += 1 if @rename_old
    raise "ERROR: only 1 option is allowed" if n > 1
      
    if name_collision
      if @rename_new
        path = @rename_new
        if FileTest.exist?(path)
          raise "ERROR: the name used when renaming must not be a file that already exist"
        end
        target_name = path
        name_collision = false
      end
    
      if @rename_old
        path = @rename_old
        if FileTest.exist?(path)
          raise "ERROR: the name used when renaming must not be a file that already exist"
        end
        FileUtils.mv(target_name, path)
        name_collision = false
      end
    
    end

    if operation == :copy
      #if @append_mode
      #  File.append(source_name, target_name)
      #else
        unless File.exist?(target_name)
          FileUtils.mkdir(target_name)
        end
        #if name_collision 
        #  FileUtils.rm_rf(target_name)
        #end
        #FileUtils.mkdir(target_name)
        #FileUtils.cp_r(source_name, target_name, :preserve => true)
      #end
    elsif operation == :move
      #if @append_mode
      #  File.append(source_name, target_name)
      #  FileUtils.rm(source_name)
      #else
        unless File.exist?(target_name)
          FileUtils.mkdir(target_name)
        end
        #if name_collision 
        #  FileUtils.rm_rf(target_name)
        #end
        #FileUtils.mkdir(target_name)
        #FileUtils.mv(source_name, target_name)
        dir_post.delete_source_path = true
      #end
    elsif operation == :skip
      # do nothing
    else
      raise "ERROR: unknown operation #{operation} in copymove code"
    end

    operation
  end
=end

  def obtain_unique_name(path, suffix)
    dirname = File.dirname(path)
    extname = File.extname(path)
    basename = File.basename(path, extname)

    i = 1
    while i < 1000
      name = basename + suffix + i.to_s + extname
      
      path2 = File.join(dirname, name)

      i += 1
      next if File.exist?(path2)
      
      return name
    end
    raise "too many retries! failed to generate a unique name for #{path} #{suffix}"
  end

  def is_name_taken(path)
    if File.symlink?(path)
      return true
    elsif File.exist?(path)
      return true
    end
    return false
  end


  
  
  def copy_skip_all
    perform_copy do |source_name, target_name, name, collision_type|
      :skip
    end
  end

  def move_skip_all
    perform_move do |source_name, target_name, name, collision_type|
      :skip
    end
  end
  
  def copy_replace_all
    perform_copy do |source_name, target_name, name, collision_type|
      :replace
    end
  end

  def move_replace_all
    perform_move do |source_name, target_name, name, collision_type|
      :replace
    end
  end

  def copy_merge_dirs_replace_files
    perform_copy do |source_name, target_name, name, collision_type|
      operation = :replace
      if collision_type == :dir
        operation = :merge
      end
      operation
    end
  end

  def move_merge_dirs_replace_files
    perform_move do |source_name, target_name, name, collision_type|
      operation = :replace
      if collision_type == :dir
        operation = :merge
      end
      operation
    end
  end

  def copy_replace_oldest
    perform_copy do |source_name, target_name, name, collision_type|
      operation = :replace
      t1 = File.mtime(source_name)
      t2 = File.mtime(target_name)
      if t1 < t2
        operation = :skip
      end
      operation
    end
  end
  
  def move_replace_oldest
    perform_move do |source_name, target_name, name, collision_type|
      operation = :replace
      t1 = File.mtime(source_name)
      t2 = File.mtime(target_name)
      if t1 < t2
        operation = :skip
      end
      operation
    end
  end

  def copy_replace_newest
    perform_copy do |source_name, target_name, name, collision_type|
      operation = :replace
      t1 = File.mtime(source_name)
      t2 = File.mtime(target_name)
      if t1 > t2
        operation = :skip
      end
      operation
    end
  end
  
  def move_replace_newest
    perform_move do |source_name, target_name, name, collision_type|
      operation = :replace
      t1 = File.mtime(source_name)
      t2 = File.mtime(target_name)
      if t1 > t2
        operation = :skip
      end
      operation
    end
  end

  def copy_replace_smaller
    perform_copy do |source_name, target_name, name, collision_type|
      operation = :replace
      size1 = File.size(source_name)
      size2 = File.size(target_name)
      if size1 < size2
        operation = :skip
      end
      operation
    end
  end
  
  def move_replace_smaller
    perform_move do |source_name, target_name, name, collision_type|
      operation = :replace
      size1 = File.size(source_name)
      size2 = File.size(target_name)
      if size1 < size2
        operation = :skip
      end
      operation
    end
  end
  
  def copy_replace_larger
    perform_copy do |source_name, target_name, name, collision_type|
      operation = :replace
      size1 = File.size(source_name)
      size2 = File.size(target_name)
      if size1 > size2
        operation = :skip
      end
      operation
    end
  end
  
  def move_replace_larger
    perform_move do |source_name, target_name, name, collision_type|
      operation = :replace
      size1 = File.size(source_name)
      size2 = File.size(target_name)
      if size1 > size2
        operation = :skip
      end
      operation
    end
  end
  
  def copy_append
    perform_copy do |source_name, target_name, name, collision_type|
      operation = :replace
      if collision_type == :file
        operation = :append
      end
      operation
    end
  end
  
  def move_append
    perform_move do |source_name, target_name, name, collision_type|
      operation = :replace
      if collision_type == :file
        operation = :append
      end
      operation
    end
  end
  
  def copy_with_prompts(ary_prompts)
    perform_copy do |source_name, target_name, name, collision_type|
      if ary_prompts.empty?
        raise "array is empty for name: #{name.inspect}"
      end
      prompt = ary_prompts.shift
      if prompt == 0
        prompt = :skip
      end
      if prompt == 1
        prompt = :replace
      end
      prompt
    end

    unless ary_prompts.empty?
      raise "array is empty. number of clashing files must match number of prompts"
    end
  end
  
  def move_with_prompts(ary_prompts)
    perform_move do |source_name, target_name, name, collision_type|
      if ary_prompts.empty?
        raise "array is empty for name: #{name.inspect}"
      end
      prompt = ary_prompts.shift
      if prompt == 0
        prompt = :skip
      end
      if prompt == 1
        prompt = :replace
      end
      prompt
    end

    unless ary_prompts.empty?
      raise "array is empty. number of clashing files must match number of prompts"
    end
  end
  
  def copy_autorename_new
    perform_copy do |source_name, target_name, name, collision_type|
      the_name = obtain_unique_name(target_name, '__new')
      [:rename_source, the_name]
    end
  end
  
  def copy_autorename_old
    perform_copy do |source_name, target_name, name, collision_type|
      the_name = obtain_unique_name(target_name, '__old')
      [:rename_target, the_name]
    end
  end
  
  def move_autorename_new
    perform_move do |source_name, target_name, name, collision_type|
      the_name = obtain_unique_name(target_name, '__new')
      [:rename_source, the_name]
    end
  end
  
  def move_autorename_old
    perform_move do |source_name, target_name, name, collision_type|
      the_name = obtain_unique_name(target_name, '__old')
      [:rename_target, the_name]
    end
  end
  

end
