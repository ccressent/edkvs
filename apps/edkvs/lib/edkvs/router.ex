defmodule EDKVS.Router do

  @doc """
  Dispatch the given `mod`, `fun`, `args` request to the appropriate node based
  on the `bucket`.
  """
  def route(bucket, mod, fun, args) do
    first = :binary.first(bucket)

    entry = Enum.find(table, fn {enum, node} -> first in enum end)
         || no_entry_error(bucket)

    if elem(entry, 1) == node() do
      apply(mod, fun, args)
    else
      sup = {EDKVS.RouterTasks, elem(entry, 1)}
      Task.Supervisor.async(sup, fn -> EDKVS.Router.route(bucket, mod, fun, args) end)
      |> Task.await()
    end
  end

  def no_entry_error(bucket) do
    raise "could not find entry for #{inspect bucket} in table #{inspect table}"
  end

  @doc """
  The routing table.
  """
  def table do
    Application.get_env(:edkvs, :routing_table)
  end
end
