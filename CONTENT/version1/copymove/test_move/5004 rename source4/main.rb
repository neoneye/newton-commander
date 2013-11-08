def run
  op = FileOperation.new
  op.move_autorename_new
end

def verify_source
  assert_source_nonexist('file1.txt')
  assert_source_nonexist('file1__new1.txt')
  assert_source_nonexist('file1__new2.txt')
  assert_source_nonexist('file1__new3.txt')
end

def verify_target
  assert_target_file('file1.txt', /target0/)
  assert_target_file('file1__new1.txt', /target1/)
  assert_target_file('file1__new2.txt', /target2/)
  assert_target_file('file1__new3.txt', /source/)
end

