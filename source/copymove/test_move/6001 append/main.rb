def run
  op = FileOperation.new
  op.move_append
end

def verify_source
  assert_source_nonexist('file1.txt')
end

def verify_target
  assert_target_file('file1.txt', /target.*source/)
end

