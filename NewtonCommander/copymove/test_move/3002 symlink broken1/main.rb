# create a broken symlink in the 'source' dir
# it becomes valid when copied to the 'target' dir

def before_run
  Dir.chdir('source') do
    `ln -s file2.txt link1.txt`
  end
end

def run
  op = FileOperation.new
  op.move_replace_all
end

def verify_source
  assert_source_nonexist('file1.txt')
  assert_source_nonexist('file2.txt')
  assert_source_nonexist('link1.txt')
end

def verify_target
  assert_target_file('file1.txt', /source/)
  assert_target_file('file2.txt', /target/)
  assert_target_link('link1.txt', /file2.txt/)
end
