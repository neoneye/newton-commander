# create a broken symlink in the 'source' dir
# when copied to the 'target' dir it continues to be broken

def before_run
  Dir.chdir('source') do
    `ln -s nonexisting.txt link1.txt`
  end
end

def run
  op = FileOperation.new
  op.copy_replace_all
end

def verify_source
  assert_source_file('file1.txt', /source/)
  assert_source_nonexist('file2.txt')
  assert_source_nonexist('nonexisting.txt')
  assert_source_link('link1.txt', /nonexisting.txt/)
end

def verify_target
  assert_target_file('file1.txt', /source/)
  assert_target_file('file2.txt', /target/)
  assert_target_nonexist('nonexisting.txt')
  assert_target_link('link1.txt', /nonexisting.txt/)
end
