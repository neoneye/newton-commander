def run
  is_cancelled = false
  op = FileOperation.new
  op.perform_copy do |source_name, target_name, name, collision_type|
    if is_cancelled
      raise "operation is cancelled we dont expect any more calls, but block was called. source_name=#{source_name}"
    end
    operation = :replace
    if name == 'dir3'
      operation = :stop
      is_cancelled = true
    end
    operation
  end
end

def verify_source
  assert_source_file('dir1/file1.txt', /^source/)
  assert_source_file('dir2/file1.txt', /^source/)
  assert_source_file('dir3/file1.txt', /^source/)
  assert_source_file('dir4/file1.txt', /^source/)
end

def verify_target
  assert_target_file('dir1/file1.txt', /source/)
  assert_target_file('dir2/file1.txt', /source/)
  assert_target_file('dir3/file1.txt', /target/)
  assert_target_file('dir4/file1.txt', /target/)
end

