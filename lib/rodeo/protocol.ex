defmodule Rodeo.Protocol do
  use GenServer

  @behaviour :ranch_protocol

  def start_link(ref, socket, transport, handler: handler) do
    GenServer.call(handler, {:set_socket, socket})
    GenServer.call(handler, {:set_transport, transport})
    pid = :proc_lib.spawn_link(__MODULE__, :init, [{ref, socket, transport, handler}])
    {:ok, pid}
  end

  def init({ref, socket, transport, handler}) do
    :ok = :ranch.accept_ack(ref)
    :ok = transport.setopts(socket, [{:active, true}])

    {:ok, state} =
      :gen_server.enter_loop(__MODULE__, [], %{
        socket: socket,
        transport: transport,
        handler: handler
      })

    {:ok, state}
  end

  def handle_info({:tcp, _socket, data}, state = %{handler: handler}) do
    GenServer.call(handler, {:tcp, data})

    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, state = %{socket: socket, transport: transport}) do
    transport.close(socket)
    {:stop, :normal, state}
  end
end
