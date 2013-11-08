def run
  op = FileOperation.new
  op.copy_autorename_new
end

def verify_source
  assert_source_file('file1.txt', /source/)
  assert_source_nonexist('file1__new1.txt')
end

def verify_target
  assert_target_file('file1.txt', /target/)
  assert_target_file('file1__new1.txt', /source/)
end

