def run
  op = FileOperation.new
  op.move_replace_all
end

def verify_source
  assert_source_nonexist('file1.txt')
  assert_source_nonexist('file2.txt')
  assert_source_nonexist('file3.txt')
end

def verify_target
  assert_target_file('file1.txt', /source/)
  assert_target_file('file2.txt', /target/)
  assert_target_file('file3.txt', /source/)
end

