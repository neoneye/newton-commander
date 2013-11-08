def run
  op = FileOperation.new
  op.exclude_dir_patterns = ['^dir1$', '^dir3$']
  op.move_replace_all
end

def verify_source
  assert_source_nonexist('file1.txt')
  assert_source_nonexist('file2.txt')
  assert_source_file('dir1/file1.txt', /source/)
  assert_source_nonexist('dir2/file1.txt')
  assert_source_file('dir3/file1.txt', /source/)
end

def verify_target
  assert_target_file('file1.txt', /source/)
  assert_target_file('file2.txt', /target/)
  assert_target_file('dir1/file1.txt', /target/)
  assert_target_file('dir2/file1.txt', /source/)
  assert_target_file('dir3/file1.txt', /target/)
end

