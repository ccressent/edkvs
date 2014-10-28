defmodule EDKVSServer do
  use Application

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Task.Supervisor, [[name: EDKVSServer.TaskSupervisor]]),
      worker(Task, [EDKVSServer, :accept, [4040]])
    ]

    opts = [strategy: :one_for_one, name: EDKVSServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Starts accepting connections on the given `port`.
  """
  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false])
    IO.puts "Accepting connections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Task.Supervisor.start_child(EDKVSServer.TaskSupervisor, fn -> serve(client) end)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    import Pipe

    msg = pipe_matching x, {:ok, x},
          read_line(socket)
          |> EDKVSServer.Command.parse()
          |> EDKVSServer.Command.run()

    write_line(socket, msg)
    serve(socket)
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp write_line(socket, msg) do
    :gen_tcp.send(socket, format_msg(msg))
  end

  defp format_msg({:ok, text}), do: text
  defp format_msg({:error, :unknown_command}), do: "UNKNOWN COMMAND\r\n"
  defp format_msg({:error, :not_found}), do: "NOT FOUND\r\n"
  defp format_msg({:error, _}), do: "ERROR\r\n"
end
