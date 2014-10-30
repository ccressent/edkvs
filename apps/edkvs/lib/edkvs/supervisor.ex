defmodule EDKVS.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  @bucket_supervisor_name EDKVS.Bucket.Supervisor
  @manager_name EDKVS.EventManager
  @ets_registry_name EDKVS.Registry
  @registry_name EDKVS.Registry

  def init(:ok) do
    ets = :ets.new(@ets_registry_name, [:set, :public, :named_table,
                                        {:read_concurrency, true}])

    children = [
      supervisor(Task.Supervisor, [[name: EDKVS.RouterTasks]]),
      worker(GenEvent, [[name: @manager_name]]),
      supervisor(EDKVS.Bucket.Supervisor, [[name: @bucket_supervisor_name]]),
      worker(EDKVS.Registry, [ets, @manager_name, @bucket_supervisor_name,
                              [name: @registry_name]])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
