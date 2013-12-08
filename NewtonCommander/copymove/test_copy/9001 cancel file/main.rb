def run
  is_cancelled = false
  op = FileOperation.new
  op.perform_copy do |source_name, target_name, name, collision_type|
    if is_cancelled
      raise "operation is cancelled we dont expect any more calls, but block was called. source_name=#{source_name}"
    end
    operation = :replace
    if name == 'file4.txt'
      operation = :stop
      is_cancelled = true
    end
    operation
  end
end

def verify_source
  assert_source_file('file1.txt', /^source/)
  assert_source_file('file2.txt', /^source/)
  assert_source_file('file3.txt', /^source/)
  assert_source_file('file4.txt', /^source/)
  assert_source_file('file5.txt', /^source/)
  assert_source_file('file6.txt', /^source/)
end

def verify_target
  assert_target_file('file1.txt', /source/)
  assert_target_file('file2.txt', /source/)
  assert_target_file('file3.txt', /source/)
  assert_target_file('file4.txt', /target/)
  assert_target_file('file5.txt', /target/)
  assert_target_file('file6.txt', /target/)
end

