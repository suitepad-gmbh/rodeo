defmodule Rodeo.Handler do
  use GenServer

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(_args) do
    {:ok, %{stubs: [], expectations: []}}
  end

  @impl true
  def handle_call({:stub, match, fun}, _from, %{stubs: stubs} = state) do
    stub_id = System.unique_integer([:monotonic, :positive])
    new_stubs = [{stub_id, match, fun, _calls = 0} | stubs]
    {:reply, stub_id, %{state | stubs: new_stubs}}
  end

  def handle_call({:set_socket, socket}, _from, state),
    do: {:reply, nil, Map.put(state, :socket, socket)}

  def handle_call({:set_transport, transport}, _from, state),
    do: {:reply, nil, Map.put(state, :transport, transport)}

  def handle_call({:tcp, data}, _from, state = %{stubs: stubs}) do
    new_stubs =
      Enum.map(stubs, fn
        {stub_id, ^data, fun, calls} when is_function(fun, 0) ->
          fun.()
          {stub_id, data, fun, calls + 1}

        {stub_id, ^data, fun, calls} when is_function(fun, 1) ->
          fun.(self())
          {stub_id, data, fun, calls + 1}

        {stub_id, ^data, fun, calls} ->
          {stub_id, data, fun, calls + 1}

        stub ->
          stub
      end)

    {:reply, nil, %{state | stubs: new_stubs}}
  end

  def handle_call({:call_count, stub_id}, _from, state = %{stubs: stubs}) do
    case List.keyfind(stubs, stub_id, 0) do
      {^stub_id, _data, _fun, calls} -> {:reply, calls, state}
      _ -> {:reply, {:error, "No stub found with ID #{stub_id}"}, state}
    end
  end

  @impl true
  def handle_cast({:send, data}, %{socket: socket, transport: transport} = state) do
    transport.send(socket, data)
    {:noreply, state}
  end
end
