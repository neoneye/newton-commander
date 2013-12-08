require 'singleton'

class CopyMoveTool
  include Singleton
  
  def initialize
    @source_dir = nil
    @target_dir = nil
    @operation = nil
  end
  
  def main
    puts "version 0.1"
    puts "date 2011-04-23"
    puts "welcome to opcoders.com's copymove tool"
    puts "type 'help' to see what commands are available"
    puts
    
    cmd = nil
    while true
      print "PROMPT> "
      $stdout.flush
      raw_cmd = gets
      
      unless raw_cmd.kind_of?(String)
        puts "ERROR: gets returned nil. Please try again."
        next
      end

      raw_cmd.strip!
      ary = raw_cmd.partition(/\s+/)
      #p ary
      cmd = ary[0]
      remain = ary[2]
      
      if cmd == 'exit'
        break
      end
      
      if cmd == 'help'
        puts "opcoders.com's copymove tool"
        puts
        puts "Commands available:"
        puts "  exit             Quit this tool"
        puts "  help             Show help"
        puts "  ping             Makes it easier to determine if commands are working"
        puts "  source_dir       Set/get the source dir. Example:  source_dir /usr/local/man"
        puts "  target_dir       Set/get the target dir. Example:  target_dir /tmp/backup"
        puts "  operation        Set/get the operation type (either copy or move). Example:  operation move"
        puts "  simulate         Simulate the copy/move operation. To measure how many bytes to be transfered."
        puts "  execute          Start the copy/move operation. Tool will exit after copy has completed."
        next
      end
      
      if cmd == 'ping'
        puts "it works"
        next
      end
      
      if cmd == 'source_dir'
        if remain.length >= 1
          @source_dir = remain
          puts "STATUS: OK"
        elsif @source_dir == nil
          puts "value is nil!"
        else
          puts "value is set to:\n#{@source_dir}"
        end
        next
      end
      
      if cmd == 'target_dir'
        if remain.length >= 1
          @target_dir = remain
          puts "STATUS: OK"
        elsif @target_dir == nil
          puts "value is nil!"
        else
          puts "value is set to:\n#{@target_dir}"
        end
        next
      end
      
      if cmd == 'operation'
        if remain.length >= 1
          if remain == 'copy'
            @operation = :copy
            puts "STATUS: OK"
          elsif remain == 'move'
            @operation = :move
            puts "STATUS: OK"
          else
            puts "ERROR: not an allowed value"
            puts "DESCRIPTION: expected operation to be either copy or move, but was: #{remain.inspect}"
          end
        elsif @operation == nil
          puts "value is nil!"
        else
          puts "value is set to:\n#{@operation}"
        end
        next
      end
      
      if cmd == 'simulate'
        puts "TODO start the operation in simulation mode"
        next
      end
      
      if cmd == 'execute'
        puts "TODO start the operation"
        break
      end
      
      puts "command not found: #{cmd.inspect}"
      puts "type 'help' to see what commands are available"
    end
    
  end
end

CopyMoveTool.instance.main