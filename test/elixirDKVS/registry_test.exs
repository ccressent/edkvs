defmodule EKVS.RegistryTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, registry} = EDKVS.Registry.start_link
    {:ok, registry: registry}
  end

  test "spawn and fetches buckets", %{registry: registry} do
    assert EDKVS.Registry.lookup(registry, "test") == :error

    EDKVS.Registry.create(registry, "test")
    assert {:ok, bucket} = EDKVS.Registry.lookup(registry, "test")

    EDKVS.Bucket.put(bucket, "milk", 1)
    assert EDKVS.Bucket.get(bucket, "milk") == 1
  end

  test "updates if a bucket disappears", %{registry: registry} do
    EDKVS.Registry.create(registry, "test")
    {:ok, bucket} = EDKVS.Registry.lookup(registry, "test")
    Agent.stop(bucket)
    assert EDKVS.Registry.lookup(registry, "test") == :error
  end
end
