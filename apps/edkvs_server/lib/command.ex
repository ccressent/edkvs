defmodule EDKVSServer.Command do
  @doc ~S"""
  Parse the given `line` into a command.

  ## Examples

      iex> EDKVSServer.Command.parse "CREATE shopping\r\n"
      {:ok, {:create, "shopping"}}

      iex> EDKVSServer.Command.parse "PUT shopping milk 1\r\n"
      {:ok, {:put, "shopping", "milk", "1"}}

      iex> EDKVSServer.Command.parse "GET shopping milk\r\n"
      {:ok, {:get, "shopping", "milk"}}

      iex> EDKVSServer.Command.parse "DELETE shopping milk\r\n"
      {:ok, {:delete, "shopping", "milk"}}

  Unknown commands or commands with the wrong number of arguments return an
  error:

      iex> EDKVSServer.Command.parse "UNKNOWN shopping milk\r\n"
      {:error, :unknown_command}

      iex> EDKVSServer.Command.parse "GET shopping\r\n"
      {:error, :unknown_command}

  """
  def parse(line) do
    case String.split(line) do
      ["CREATE", bucket]          -> {:ok, {:create, bucket}}
      ["DELETE", bucket, key]     -> {:ok, {:delete, bucket, key}}
      ["GET", bucket, key]        -> {:ok, {:get, bucket, key}}
      ["PUT", bucket, key, value] -> {:ok, {:put, bucket, key, value}}
      _                           -> {:error, :unknown_command}
    end
  end

  @doc """
  Runs the given command.
  """
  def run(command)

  def run({:create, bucket}) do
    EDKVS.Registry.create(EDKVS.Registry, bucket)
    {:ok, "OK\r\n"}
  end

  def run({:delete, bucket, key}) do
    lookup bucket, fn pid ->
      EDKVS.Bucket.delete(pid, key)
      {:ok, "OK\r\n"}
    end
  end

  def run({:get, bucket, key}) do
    lookup bucket, fn pid ->
      value = EDKVS.Bucket.get(pid, key)
      {:ok, "#{value}\r\nOK\r\n"}
    end
  end

  def run({:put, bucket, key, value}) do
    lookup bucket, fn pid ->
      EDKVS.Bucket.put(pid, key, value)
      {:ok, "OK\r\n"}
    end
  end

  defp lookup(bucket, callback) do
    case EDKVS.Registry.lookup(EDKVS.Registry, bucket) do
      {:ok, pid} -> callback.(pid)
      :error     -> {:error, :not_found}
    end
  end
end
