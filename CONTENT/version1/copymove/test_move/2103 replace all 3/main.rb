def run
  op = FileOperation.new
  op.move_replace_all
end

def verify_source
  assert_source_nonexist('file1.txt')
  assert_source_nonexist('file2.txt')
  assert_source_nonexist('file3.txt')
  assert_source_nonexist('file4.txt')
  assert_source_nonexist('dir1')
end

def verify_target
  assert_target_file('file1.txt', /source/)
  assert_target_file('file2.txt', /source/)
  assert_target_file('file3.txt', /target/)
  assert_target_file('file4.txt', /target/)
  assert_target_file('dir1/file1.txt', /source/)
  assert_target_file('dir1/dir2/file1.txt', /source/)
  assert_target_file('dir1/dir2/file2.txt', /source/)
end
