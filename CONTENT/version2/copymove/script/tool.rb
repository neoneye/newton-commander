require 'pty'
require 'expect'


class Tool
  EXPECT_TIMEOUT = 3
  def initialize
    @version = nil
    
    @r_f = nil
    @w_f = nil
  end
  
  attr_reader :version
  
  def source_dir=(value)
    set_value_for_command('source_dir', value)
  end 

  def source_dir
    get_value_from_command('source_dir')
  end
  
  def target_dir=(value)
    set_value_for_command('target_dir', value)
  end 

  def target_dir
    get_value_from_command('target_dir')
  end

  def operation_move
    set_value_for_command('operation', 'move')
  end 

  def operation_copy
    set_value_for_command('operation', 'copy')
  end 

  def operation
    get_value_from_command('operation')
  end

  def simulate
    #
  end

  def execute
    #
  end

  
  
  def set_value_for_command(command, value)
    assign_successful = false
    @w_f.print "#{command} #{value}\n"
    @r_f.expect(/^PROMPT> /, EXPECT_TIMEOUT) do |output|
      if output == nil
        raise 'timeout'
      end
      unless output.kind_of?(Array)
        raise "expect should never return anyting but arrays"
      end
      unless output.count >= 1
        raise "expect should always return an array with minimum 1 element"
      end
      s = output[0]
      if s =~ /STATUS: OK/
        assign_successful = true
      elsif s =~ /ERROR: not an allowed value/
        raise "not an allowed value"
      elsif s =~ /command not found/
        raise "command not found: #{s}"
      else
        raise "unknown response from tool: #{s}"
      end
    end
    unless assign_successful
      raise "assign was unsuccessful"
    end
    return nil
  end
  

  def get_value_from_command(command)
    obtained_result = false
    result = nil
    @w_f.print "#{command}\n"
    @r_f.expect(/^PROMPT> /, EXPECT_TIMEOUT) do |output|
      if output == nil
        raise 'timeout'
      end
      unless output.kind_of?(Array)
        raise "expect should never return anyting but arrays"
      end
      unless output.count >= 1
        raise "expect should always return an array with minimum 1 element"
      end
      s = output[0]
      if s =~ /command not found/
        raise 'command not found'
      end
      s_no_cr = s.gsub(/\r/, '')
      if s_no_cr =~ /^value is set to:\n(.*?)$/m
        result = $1
        obtained_result = true
      elsif s_no_cr =~ /^value is nil!/
        result = nil
        obtained_result = true
      else
        raise "unknow response from tool: #{s.inspect}"
      end
    end
    unless obtained_result
      raise "failed to obtain result"
    end
    return result
  end
 
  
  
  def run(&block)

    PTY.spawn("ruby copymove_tool.rb") do |r_f, w_f, pid|
      w_f.sync = true

      $expect_verbose = false
      
      r_f.expect(/^PROMPT> /) do |output|
        s = output[0]
        version = 'unknown'
        if s =~ /^version (.+)$/i
          version = $1.strip
        end
        @version = version
      end
      
      if block
        @r_f = r_f
        @w_f = w_f

        block.call

        @r_f = nil
        @w_f = nil
      end



#      r_f.expect(/^PROMPT> /) do
#        w_f.print "exit\n"
#      end
    end

  end
  
end