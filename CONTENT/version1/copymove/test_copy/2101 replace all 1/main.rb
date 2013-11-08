def run
  op = FileOperation.new
  op.copy_replace_all
end

def verify_source
  assert_source_file('file1.txt', /source/)
end

def verify_target
  assert_target_file('file1.txt', /source/)
end

