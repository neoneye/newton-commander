require 'loadobject'
require 'testbase'
require 'fileoperation'
require 'track_progress'

class TestCommand

  def initialize
    @progress = nil
    @path_to_test_dir = nil
    @basename = nil
    @title = nil
    @obj = nil
    @work_dir = nil
    @path_to_test_dir_source = nil
    @path_to_test_dir_target = nil
  end
  attr_accessor :progress
  attr_accessor :basename, :title, :obj, :work_dir
  attr_accessor :path_to_test_dir
  attr_accessor :path_to_test_dir_source
  attr_accessor :path_to_test_dir_target
  
  def self.create_command(path_to_test_dir)
    cmd = TestCommand.new
    cmd.progress = TrackProgress.instance
    cmd.path_to_test_dir = path_to_test_dir
    cmd.basename = File.basename(path_to_test_dir)
    cmd.title = cmd.basename
    cmd.path_to_test_dir_source = File.join(cmd.path_to_test_dir, 'source')
    cmd.path_to_test_dir_target = File.join(cmd.path_to_test_dir, 'target')

    Dir.chdir(path_to_test_dir) do
      if File.file?('title.txt')
        cmd.title = IO.read('title.txt')
      end

      unless File.directory?(cmd.path_to_test_dir_source)
        raise "ERROR: found no source dir for test dir #{path_to_test_dir}"
      end

      unless File.directory?(cmd.path_to_test_dir_target)
        raise "ERROR: found no target dir for test dir #{path_to_test_dir}"
      end

      if File.file?('main.rb')
        cmd.obj = AnonymousSubclass.create_object('main.rb', TestBase)
      else
        puts "ERROR: Found no main.rb code file within the dir: #{path_to_test_dir}"
        raise 'missing main.rb'
      end

    end
    
    cmd
  end

  def pretty_name
    s = @basename
    if @basename != @title
      s += " - #{@title}"
    end
    s
  end

  def execute
    raise 'dunno where to put the result, the workdir is nil' unless @work_dir
    unless File.directory?(@work_dir)
      # puts "creating work dir. #{@work_dir}. #{Dir.pwd}"
      Dir.mkdir(@work_dir, 0700)
    end
    Dir.chdir(@work_dir) do
      File.open("log.txt", "w+") do |logfile|
        execute_inner(logfile)
      end
    end
  end

  def execute_inner(logfile)
    FileUtils.cp_r(@path_to_test_dir_source, '.', :preserve => true)
    FileUtils.cp_r(@path_to_test_dir_target, '.', :preserve => true)
    
    @progress.logfile = logfile
    
    exceptions = []

    logfile.write("------------------\n")
    logfile.write("RUN\n")
    logfile.write("------------------\n")
    @progress.run_phase do
      begin
        @obj.before_run
        @obj.run
        logfile.write("run -> ok\n")
      rescue => e
        logfile.write("run -> error!\n" + string_from_exception(e, '    '))
        exceptions << e
        @progress.exception_occured
      end
    end
    logfile.write("\n\n\n")

    if File.file?("copymove_output.txt")
      s = IO.read("copymove_output.txt")
      logfile.write("cat copymove_output.txt\n\n")
      logfile.write(s)
      logfile.write("\n\n\n")
      FileUtils.rm("copymove_output.txt")
    else
      logfile.write("no output because there is no copymove_output.txt file")
    end

    logfile.write("------------------\n")
    logfile.write("VERIFY SOURCE\n")
    logfile.write("------------------\n")
    @progress.verify_source do
      begin
        @obj.verify_source
        logfile.write("verify_source -> ok\n")
      rescue => e
        logfile.write("verify_source -> error!\n" + string_from_exception(e, '    '))
        exceptions << e
        @progress.exception_occured
      end
    end
    logfile.write("\n\n\n")

    logfile.write("------------------\n")
    logfile.write("VERIFY TARGET\n")
    logfile.write("------------------\n")
    @progress.verify_target do
      begin
        @obj.verify_target
        logfile.write("verify_target -> ok\n")
      rescue => e
        logfile.write("verify_target -> error!\n" + string_from_exception(e, '    '))
        exceptions << e
        @progress.exception_occured
      end
    end
    
    @progress.print_status(exceptions)
    
    if exceptions.empty?
      File.open('OK', 'w+') {|f| f.write('test_status: success') }
      @progress.number_of_successful_tests += 1          
    else
      File.open('ERROR', 'w+') {|f| f.write('test_status: failed') }
      @progress.number_of_failed_tests += 1
    end

    @progress.logfile = nil
  end
  
  def string_from_exception(e, indent)
    rows = []
    rows += e.to_s.split("\n")
    rows += e.backtrace
    rows.map{|s| "#{indent}#{s}"}.join("\n")
  end
  
end
