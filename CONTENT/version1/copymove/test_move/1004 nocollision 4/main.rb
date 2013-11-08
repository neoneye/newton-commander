def before_run
  Dir.chdir('source') do
    `ln -s link1.txt link1.txt`
  end
end

def run
  op = FileOperation.new
  op.move_replace_all
end

def verify_source
  assert_source_nonexist('link1.txt')
end

def verify_target
  assert_target_link('link1.txt', /link1.txt/)
  assert_target_file('ignore1.txt', /source/)
  assert_target_file('ignore2.txt', /target/)
end

