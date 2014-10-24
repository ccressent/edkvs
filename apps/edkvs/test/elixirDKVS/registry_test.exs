defmodule EDKVS.RegistryTest do
  use ExUnit.Case, async: true

  defmodule Forwarder do
    use GenEvent

    def handle_event(event, parent) do
      send parent, event
      {:ok, parent}
    end
  end

  setup do
    ets      = :ets.new(:registry_table, [:set, :public])
    registry = start_registry(ets)
    {:ok, registry: registry, ets: ets}
  end

  defp start_registry(ets) do
    {:ok, sup}      = EDKVS.Bucket.Supervisor.start_link
    {:ok, manager}  = GenEvent.start_link
    {:ok, registry} = EDKVS.Registry.start_link(ets, manager, sup)

    GenEvent.add_mon_handler(manager, Forwarder, self())
    registry
  end


  test "spawn and fetches buckets", %{registry: registry, ets: ets} do
    assert EDKVS.Registry.lookup(ets, "test") == :error

    EDKVS.Registry.create(registry, "test")
    assert {:ok, bucket} = EDKVS.Registry.lookup(ets, "test")

    EDKVS.Bucket.put(bucket, "milk", 1)
    assert EDKVS.Bucket.get(bucket, "milk") == 1
  end

  test "updates if a bucket disappears", %{registry: registry, ets: ets} do
    EDKVS.Registry.create(registry, "test")
    {:ok, bucket} = EDKVS.Registry.lookup(ets, "test")

    Agent.stop(bucket)
    assert_receive {:exit, "test", ^bucket}
    assert EDKVS.Registry.lookup(ets, "test") == :error
  end

  test "sends events on create and crash", %{registry: registry, ets: ets} do
    EDKVS.Registry.create(registry, "test")
    {:ok, bucket} = EDKVS.Registry.lookup(ets, "test")
    assert_receive {:create, "test", ^bucket}

    Agent.stop(bucket)
    assert_receive {:exit, "test", ^bucket}
  end

  test "removes bucket on crash", %{registry: registry, ets: ets} do
    EDKVS.Registry.create(registry, "test")
    {:ok, bucket} = EDKVS.Registry.lookup(ets, "test")

    Process.exit(bucket, :shutdown)
    assert_receive {:exit, "test", ^bucket}
    assert EDKVS.Registry.lookup(ets, "test") == :error
  end

  test "can lookup existing buckets after crash", %{registry: registry, ets: ets} do
    EDKVS.Registry.create(registry, "test")

    Process.unlink(registry)
    Process.exit(registry, :shutdown)
    start_registry(ets)

    assert EDKVS.Registry.lookup(ets, "test") != :error
  end

  test "monitors existing buckets", %{registry: registry, ets: ets} do
    EDKVS.Registry.create(registry, "test")

    Process.unlink(registry)
    Process.exit(registry, :shutdown)
    start_registry(ets)

    {:ok, bucket} = EDKVS.Registry.lookup(ets, "test")
    Process.exit(bucket, :shutdown)

    assert_receive {:exit, "test", ^bucket}
    assert EDKVS.Registry.lookup(ets, "test") == :error
  end
end
