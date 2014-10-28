defmodule EDKVSServerTest do
  use ExUnit.Case

  setup do
    Logger.remove_backend(:console)
    Application.stop(:edkvs)
    :ok = Application.start(:edkvs)
    Logger.add_backend(:console, flush: true)
    :ok
  end

  setup do
    opts = [:binary, packet: :line, active: false]
    {:ok, socket} = :gen_tcp.connect('localhost', 4040, opts)
    {:ok, socket: socket}
  end

  test "server interaction", %{socket: socket} do
    assert send_and_recv(socket, "UNKNOWN test\r\n")     == "UNKNOWN COMMAND\r\n"
    assert send_and_recv(socket, "GET bucket key\r\n")   == "NOT FOUND\r\n"
    assert send_and_recv(socket, "CREATE bucket\r\n")    == "OK\r\n"
    assert send_and_recv(socket, "PUT bucket key 3\r\n") == "OK\r\n"

    assert send_and_recv(socket, "GET bucket key\r\n") == "3\r\n"
    assert send_and_recv(socket, "") == "OK\r\n"

    assert send_and_recv(socket, "DELETE bucket key\r\n") == "OK\r\n"

    assert send_and_recv(socket, "GET bucket key\r\n") == "\r\n"
    assert send_and_recv(socket, "") == "OK\r\n"
  end

  defp send_and_recv(socket, command) do
    :ok = :gen_tcp.send(socket, command)
    {:ok, data} = :gen_tcp.recv(socket, 0, 1000)
    data
  end
end
