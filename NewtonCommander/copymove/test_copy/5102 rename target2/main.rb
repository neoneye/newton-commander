def run
  op = FileOperation.new
  op.copy_autorename_old
end

def verify_source
  assert_source_file('file1.txt', /source/)
  assert_source_nonexist('file1__old1.txt')
end

def verify_target
  assert_target_file('file1.txt', /source/)
  assert_target_file('file1__old1.txt', /target/)
end

