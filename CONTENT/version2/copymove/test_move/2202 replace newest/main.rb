def before_run
  `touch -t 200012240000 source/file1.txt`
  `touch -t 200012010000 target/file1.txt`
  `touch -t 200012010000 source/file2.txt`
  `touch -t 200012240000 target/file2.txt`
end
  
def run
  op = FileOperation.new
  op.move_replace_newest
end

def verify_source
  assert_source_file('file1.txt', /source/)
  assert_source_nonexist('file2.txt')
end

def verify_target
  assert_target_file('file1.txt', /target/)
  assert_target_file('file2.txt', /source/)
end

