def run
  op = FileOperation.new
  op.copy_replace_larger
end

def verify_source
  assert_source_file('file1.txt', /source/)
  assert_source_file('file2.txt', /source/)
end

def verify_target
  assert_target_file('file1.txt', /target/)
  assert_target_file('file2.txt', /source/)
end

