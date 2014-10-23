defmodule EKVS.RegistryTest do
  use ExUnit.Case, async: true

  defmodule Forwarder do
    use GenEvent

    def handle_event(event, parent) do
      send parent, event
      {:ok, parent}
    end
  end

  setup do
    {:ok, manager}  = GenEvent.start_link
    {:ok, registry} = EDKVS.Registry.start_link(manager)

    GenEvent.add_mon_handler(manager, Forwarder, self())
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

  test "sends events on create and crash", %{registry: registry} do
    EDKVS.Registry.create(registry, "test")
    {:ok, bucket} = EDKVS.Registry.lookup(registry, "test")
    assert_receive {:create, "test", ^bucket}

    Agent.stop(bucket)
    assert_receive {:exit, "test", ^bucket}
  end
end
