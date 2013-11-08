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
  n1 = 0
  n2 = 0
  
  op = FileOperation.new
  op.perform_copy do |source_name, target_name, name, collision_type|
    operation = :no_such_operation

    if name == 'file1.txt'
      
      if n1 == 0
        operation = :retry
        
      elsif n1 == 1
        operation = :retry
        
      elsif n1 == 2
        FileUtils.mv(File.join('target', name), File.join('target', 'collision_file1.txt'))
        operation = :retry

      elsif n1 == 3
        raise "too many retries"
      end

      n1 += 1
    end
    
    if name == 'file2.txt'
      
      if n2 == 0
        operation = :retry
        
      elsif n2 == 1
        operation = :retry
        
      elsif n2 == 2
        FileUtils.mv(File.join('target', name), File.join('target', 'collision_file2.txt'))
        operation = :retry

      elsif n2 == 3
        raise "too many retries"
      end

      n2 += 1
    end
    
    operation
  end
end

def verify_source
  assert_source_file('file1.txt', /source/)
  assert_source_file('file2.txt', /source/)
  assert_source_nonexist('collision_file1.txt')
  assert_source_nonexist('collision_file2.txt')
end

def verify_target
  assert_target_file('file1.txt', /source/)
  assert_target_file('file2.txt', /source/)
  assert_target_file('collision_file1.txt', /target/)
  assert_target_file('collision_file2.txt', /target/)
end

