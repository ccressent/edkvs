defmodule EDKVS.RouterTest do
  use ExUnit.Case, async: true

  @tag :distributed
  test "route requests accross nodes" do
    assert EDKVS.Router.route("hello", Kernel, :node, []) == :"foo@ccmbp"
    assert EDKVS.Router.route("world", Kernel, :node, []) == :"bar@ccmbp"
  end

  test "raises on unknown entries" do
    assert_raise RuntimeError, ~r/could not find entry/, fn ->
      EDKVS.Router.route(<<0>>, Kernel, :node, [])
    end
  end
end
