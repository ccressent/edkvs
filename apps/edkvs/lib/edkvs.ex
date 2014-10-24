defmodule EDKVS do
  use Application

  def start(_type, _args) do
    EDKVS.Supervisor.start_link
  end
end
