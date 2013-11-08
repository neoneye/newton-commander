def run
  op = FileOperation.new
  op.copy_with_prompts([1, 0, 1, 0])
end

def verify_source
  assert_source_file('file1.txt', /source/)
  assert_source_file('file2.txt', /source/)
  assert_source_file('file3.txt', /source/)
  assert_source_file('file4.txt', /source/)
end

def verify_target
  assert_target_file('file1.txt', /source/)
  assert_target_file('file2.txt', /target/)
  assert_target_file('file3.txt', /source/)
  assert_target_file('file4.txt', /target/)
end

