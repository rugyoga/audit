defmodule FileCacheTest do
  use ExUnit.Case, async: true
  import Mock
  alias Audit.FileCache

  @file_contents ["word"]

  test "get/1" do
    with_mock File, stream!: fn :filename -> @file_contents end do
      a = FileCache.get(:filename)
      b = FileCache.get(:filename)
      assert a == b
      assert a == @file_contents
      assert_called_exactly(File.stream!(:filename), 1)
    end
  end
end
