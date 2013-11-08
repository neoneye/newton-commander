def run
  op = FileOperation.new
  op.exclude_file_patterns = ['^file2\.txt$', '^exclude']
  op.copy_replace_all
end

def verify_source
  assert_source_file('file1.txt', /source/)
  assert_source_file('file2.txt', /source/)
  assert_source_file('file3.txt', /source/)             
  assert_source_file('exclude1.txt', /source/)
  assert_source_file('exclude2.txt', /source/)
  assert_source_file('exclude3.txt', /source/)
end

def verify_target
  assert_target_file('file1.txt', /source/)
  assert_target_file('file2.txt', /target/)
  assert_target_file('file3.txt', /source/)
  assert_target_nonexist('exclude1.txt')
  assert_target_nonexist('exclude2.txt')
  assert_target_nonexist('exclude3.txt')
end

