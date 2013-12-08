=begin

:retry is useful in case of copying to a remote folder where your friend is
sitting in the other end. Your friend works with the file at the same time you
are working with the files. In some cases you are just waiting for your
friend to make some change to a file, so that you can copy in your file
where it's supposed to be. This is what :retry is useful for.

An error occured copying 'the-movie.mp4':
The process cannot access the file because it is being used by another process.
Retry | Skip | Abort operation

=end

def run
  n = 0
  
  op = FileOperation.new
  op.perform_move do |source_name, target_name, name, collision_type|
    operation = :no_such_operation

    if name == 'file1.txt'
      
      if n == 0
        operation = :retry
        
      elsif n == 1
        operation = :retry
        
      elsif n == 2
        FileUtils.mv(File.join('target', name), File.join('target', 'collision_file1.txt'))
        operation = :retry

      elsif n == 3
        raise "too many retries"
      end

      n += 1
    end
    
    operation
  end
end

def verify_source
  assert_source_nonexist('file1.txt')
  assert_source_nonexist('collision_file1.txt')
end

def verify_target
  assert_target_file('file1.txt', /source/)
  assert_target_file('collision_file1.txt', /target/)
end

