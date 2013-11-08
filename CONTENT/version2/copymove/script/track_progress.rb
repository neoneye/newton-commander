require 'singleton'

class TrackProgress
  include Singleton
  
  attr_accessor :verbose
  attr_accessor :pretty
  attr_accessor :short
  attr_accessor :number_of_exceptions
  attr_accessor :number_of_successful_tests
  attr_accessor :number_of_failed_tests
  attr_accessor :logfile
  
  def initialize
    @number_of_exceptions = 0
    @number_of_successful_tests = 0
    @number_of_failed_tests = 0
    @short = true
  end
  
  def show_commands(names)
    if @verbose
      puts "---------------------------------------------"
      puts "commands:"
      puts "---------------------------------------------"
      puts names.join("\n")
      puts
    end
  end

  def run_command(executing_command_label, command_pretty_name, &block)
    if @verbose
      puts "---------------------------------------------"
      puts "#{executing_command_label}: #{command_pretty_name}"
      puts "---------------------------------------------"
    end
    if @pretty
      s = "#{executing_command_label}: #{command_pretty_name}"
      s = "%-40s" % s
      print "#{s}    ["
      $stdout.flush
    end
    block.call
    if @verbose
      puts
    end
    if @pretty
      print "\n"
      $stdout.flush
    end
  end
  
  def run_phase(&block)
    if @verbose
      puts 'RUN'
    end
    block.call
    if @pretty
      print "|"
      $stdout.flush
    end
  end
  
  def verify_source(&block)
    if @verbose
      puts 'VERIFY_SOURCE'
    end
    block.call
    if @pretty
      print "|"
      $stdout.flush
    end
  end
  
  def verify_target(&block)
    if @verbose
      puts 'VERIFY_TARGET'
    end
    block.call
    if @pretty
      print "]"
      $stdout.flush
    end
  end
  
  def exception_occured
    if @verbose
      puts 'EXCEPTION OCCURED'
    end
    if @pretty
      print "E"
      $stdout.flush
    end
    
    @number_of_exceptions += 1
  end
  
  def register_progress(assertion_name, &block)
    if @logfile
      @logfile.write("#{assertion_name} ")
    end
    if @verbose
      s = "%-30s" % assertion_name
      print "#{s} "
      $stdout.flush
    end
    block.call
    if @logfile
      @logfile.write(" ok\n")
    end
    if @verbose
      print "ok\n"
      $stdout.flush
    end
    if @pretty
      print "."
      $stdout.flush
    end
  end

  def print_status(exceptions)

    exception_count = exceptions.count
    if exception_count < 1
      if @verbose
        puts 'DONE'
      end

      return
    end
    
    if @short
      # print "  FAILED"
      return
    end

    if @verbose
      print "DONE, but exceptions occured!\n\n"
    end
    if @pretty
      print "  FAILED\n\n"
    end

    rows = []
    exceptions.each_with_index do |e, index|
      if index > 0
        rows << ''
      end

      if exception_count >= 2
        e_index = index + 1
        rows << "Exception #{e_index} of #{exception_count}"
      end

      rows += e.to_s.split("\n")
      btrows = e.backtrace

      if @pretty
        if btrows.count > 3
          btrows = btrows[0..3]
          btrows << "<truncated backtrace>"
        end
      end
      
      rows += btrows
    end

    puts rows.map{|s| "  #{s}"}.join("\n")
  end
  
  
end
  