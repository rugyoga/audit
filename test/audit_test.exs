defmodule AuditTest do
  use Audit
  use ExUnit.Case, async: true

  defmodule TestStruct do
    defstruct foo: "default", __audit_trail__: nil
  end

  describe "audit" do
    test "trail" do
      r = %TestStruct{}
      assert r |> audit_real |> trail == {r, __ENV__.file, __ENV__.line}
    end

    test "nth" do
      a = %TestStruct{}
      b = a |> audit_real |> struct(foo: "bar")
      c = b |> audit_real |> struct(foo: "baz")
      assert c |> nth(2) == a
      assert c.foo == "baz"
      assert (c |> trail |> record).foo == "bar"
      assert c |> trail |> record |> trail |> record == a
    end

    test "record" do
      assert record(payload(:record, __ENV__)) == :record
    end

    test "file" do
      assert file(payload(:record, __ENV__)) == __ENV__.file
    end

    test "line" do
      assert line(payload(:record, __ENV__)) == __ENV__.line
    end
  end
end
