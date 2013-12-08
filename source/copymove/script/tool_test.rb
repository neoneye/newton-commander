require "tool"
require "test/unit"

class TestTool < Test::Unit::TestCase
 
  def test_version
    t = Tool.new
    t.run
    assert_equal("0.1", t.version)
  end
 
  def test_source_dir
    t = Tool.new
    was_called = false
    t.run do
      was_called = true
      assert_nil(t.source_dir)
      t.source_dir = 'sldfjlk'
      assert_equal('sldfjlk', t.source_dir)
    end
    assert_equal(true, was_called)
  end
 
  def test_target_dir
    t = Tool.new
    was_called = false
    t.run do
      was_called = true
      assert_nil(t.target_dir)
      t.target_dir = 'abcdefg'
      assert_equal('abcdefg', t.target_dir)
    end
    assert_equal(true, was_called)
  end
 
  def test_operation_copy
    t = Tool.new
    was_called = false
    t.run do
      was_called = true
      assert_nil(t.operation)
      t.operation_copy
      assert_equal('copy', t.operation)
    end
    assert_equal(true, was_called)
  end
 
  def test_operation_move
    t = Tool.new
    was_called = false
    t.run do
      was_called = true
      assert_nil(t.operation)
      t.operation_move
      assert_equal('move', t.operation)
    end
    assert_equal(true, was_called)
  end
 
  def test_copy1
    t = Tool.new
    was_called = false
    t.run do
      was_called = true
      assert_nil(t.operation)
      t.source_dir = '/usr/local/man'
      t.target_dir = '/tmp'
      t.operation_copy
      t.simulate  # TODO: how to test?
      t.execute   # TODO: how to test?
    end
    assert_equal(true, was_called)
  end
 
  def test_move1
    t = Tool.new
    was_called = false
    t.run do
      was_called = true
      assert_nil(t.operation)
      t.source_dir = '/usr/local/man'
      t.target_dir = '/tmp'
      t.operation_move
      t.simulate  # TODO: how to test?
      t.execute   # TODO: how to test?
    end
    assert_equal(true, was_called)
  end
 
end