def run
  op = FileOperation.new
  op.perform_copy do |source_name, target_name, name, collision_type|
    operation = :replace
    if name == 'file1.txt'
      operation = [:rename_source, 'file1_new.txt']
    end
    operation
  end
end

def verify_source
  assert_source_file('file1.txt', /source/)
  assert_source_nonexist('file1_new.txt')
end

def verify_target
  assert_target_file('file1.txt', /target/)
  assert_target_file('file1_new.txt', /source/)
end

