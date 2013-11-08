def run
  op = FileOperation.new
  op.move_replace_all
end

def verify_source
  assert_source_nonexist('dir1/file1.txt')
  assert_source_nonexist('dir2/file1.txt')
  assert_source_nonexist('dir3/file1.txt')
end

def verify_target
  assert_target_file('dir1/file1.txt', /source/)
  assert_target_file('dir2/file1.txt', /source/)
  assert_target_file('dir3/file1.txt', /source/)
  assert_target_file('ignore.txt', /target/)
end

