require 'track_progress'

class TestBase
  FILENAME = nil
  
  def filename
    self.class::FILENAME
  end

  def before_run
    # overloading is optional, subclasses doesn't have to implement this
  end

  def run
    # subclasses must implement this method
    puts "run - not overloaded. file=#{filename}"
  end

  # check that all source files are ok
  def verify_source
    # subclasses must implement this method
    puts "verify_source - not overloaded. file=#{filename}"
  end
  
  # check that all target files are ok
  def verify_target
    # subclasses must implement this method
    puts "verify_target - not overloaded. file=#{filename}"
  end
  
  def assert_file_inner(path, pattern)
    s = IO.read(path)
    unless pattern.kind_of?(Regexp)
      raise "expected pattern #{pattern} to be a regex"
    end
    unless s =~ pattern
      raise "expected #{path} to match pattern #{pattern}, but content is: #{s.inspect}"
    end
  end
  
  def assert_source_file(filename, pattern)
    TrackProgress.instance.register_progress('assert_source_file') do
      
      assert_file_inner(File.join('source', filename), pattern)
      
    end
  end

  def assert_target_file(filename, pattern)
    TrackProgress.instance.register_progress('assert_target_file') do

      assert_file_inner(File.join('target', filename), pattern)

    end
  end
  
  def assert_link_inner(path, pattern)
    unless File.symlink?(path)
      raise "expected #{path} to be a symlink, but it's not"
    end
    s = File.readlink(path)
    unless pattern.kind_of?(Regexp)
      raise "expected pattern #{pattern} to be a regex"
    end
    unless s =~ pattern
      raise "expected #{path} to match pattern #{pattern}, but link points to: #{s.inspect}"
    end
  end
  
  def assert_source_link(filename, pattern)
    TrackProgress.instance.register_progress('assert_source_link') do
      
      assert_link_inner(File.join('source', filename), pattern)
      
    end
  end

  def assert_target_link(filename, pattern)
    TrackProgress.instance.register_progress('assert_target_link') do

      assert_link_inner(File.join('target', filename), pattern)

    end
  end

  def assert_source_nonexist(filename)
    TrackProgress.instance.register_progress('assert_source_nonexist') do
      
      path = File.join('source', filename)
      if File.symlink?(path)
        raise "expected #{path} to not exist, but symlink exists!"
      elsif File.exist?(path)
        raise "expected #{path} to not exist, but file exists!"
      end
      
    end
  end

  def assert_target_nonexist(filename)
    TrackProgress.instance.register_progress('assert_target_nonexist') do

      path = File.join('target', filename)
      if File.symlink?(path)
        raise "expected #{path} to not exist, but symlink exists!"
      elsif File.exist?(path)
        raise "expected #{path} to not exist, but item exists!"
      end

    end
  end

  def assert_not_implemented
    TrackProgress.instance.register_progress('assert_not_implemented') do
      raise "this test is not yet fully implemented"
    end
  end

end
