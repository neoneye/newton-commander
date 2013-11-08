def run
  op = FileOperation.new
  op.move_autorename_old
end

def verify_source
  assert_source_nonexist('file1.txt')
  assert_source_nonexist('file1__old1.txt')
  assert_source_nonexist('file1__old2.txt')
  assert_source_nonexist('file1__old3.txt')
end

def verify_target
  assert_target_file('file1.txt', /source/)
  assert_target_file('file1__old1.txt', /target1/)
  assert_target_file('file1__old2.txt', /target2/)
  assert_target_file('file1__old3.txt', /target3/)
end

