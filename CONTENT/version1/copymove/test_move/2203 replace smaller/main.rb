def run
  op = FileOperation.new
  op.move_replace_smaller
end

def verify_source
  assert_source_nonexist('file1.txt')
  assert_source_file('file2.txt', /source/)
end

def verify_target
  assert_target_file('file1.txt', /source/)
  assert_target_file('file2.txt', /target/)
end

