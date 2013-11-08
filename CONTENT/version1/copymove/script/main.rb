require 'fileutils'
require 'tmpdir'
require 'dir_chdir_glob_all'
require 'testcommand'
require 'track_progress'

TESTAREA_DIR = 'testarea'

class Main
  
  def initialize(config)
    @testdir = config['testdir']
    raise 'no testdir in config' unless @testdir 

    @outputdir = config['outputdir']
    raise 'no outputdir in config' unless @outputdir 

    @executing_command_label = config['executing_comand_label'] || 'executing command'
    
    @console_output_verbose = true             
    @console_output_pretty = false
    if config['console_output'] == 'verbose'
      @console_output_verbose = true
      @console_output_pretty = false
    elsif config['console_output'] == 'pretty'
      @console_output_verbose = false
      @console_output_pretty = true
    end
    
  end
  
  def run_all_tests
    progress = TrackProgress.instance
    progress.verbose = @console_output_verbose
    progress.pretty = @console_output_pretty
    
    
    unless File.directory?(TESTAREA_DIR)
      FileUtils.mkdir(TESTAREA_DIR)
    end
    
    workdir = File.expand_path(File.join(TESTAREA_DIR, @outputdir))
    if File.directory?(workdir)
      puts "ERROR: #{workdir} already exists, try again"
      exit
    end
    FileUtils.mkdir(workdir)
    
    Dir.chdir(workdir) do

      commands = create_commands_from_test_dir(@testdir)

      # show an overview of all the commands that we are going to execute
      names = commands.map {|command| command.pretty_name }
      progress.show_commands(names)

      # assign work dirs.. e.g.  /var/tmp/1005 advanced merge
      commands.each do |command|
        command.work_dir = File.join(workdir, command.basename)
      end

      # run the commands
      commands.each do |command|
        
        progress.run_command(@executing_command_label, command.pretty_name) do
          command.execute
        end

      end

    end

  end
  
  def create_commands_from_test_dir(path_to_test_dir)
    commands = []
    Dir.chdir_glob_all(path_to_test_dir) do |absolute_path|
      commands << TestCommand.create_command(absolute_path)
    end
    commands
  end


end # class Main
