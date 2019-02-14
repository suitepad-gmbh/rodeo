defmodule Rodeo.Handler do
  use GenServer

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(_args) do
    {:ok, %{stubs: []}}
  end

  @impl true
  def handle_call({:stub, match, fun}, _from, %{stubs: stubs} = state) do
    new_stubs = [{match, fun} | stubs]
    {:reply, nil, %{state | stubs: new_stubs}}
  end

  def handle_call({:set_socket, socket}, _from, state),
    do: {:reply, nil, Map.put(state, :socket, socket)}

  def handle_call({:set_transport, transport}, _from, state),
    do: {:reply, nil, Map.put(state, :transport, transport)}

  def handle_call({:tcp, data}, _from, state = %{stubs: stubs}) do
    Enum.each(stubs, fn
      {^data, fun} -> fun.(self())
      _ -> nil
    end)

    {:reply, nil, state}
  end

  @impl true
  def handle_cast({:send, data}, %{socket: socket, transport: transport} = state) do
    transport.send(socket, data)
    {:noreply, state}
  end
end
