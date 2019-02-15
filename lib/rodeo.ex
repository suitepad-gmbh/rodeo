defmodule Rodeo do
  @moduledoc """
  Rodeo provides a convenient way for creating a plain TCP mock server. This is
  useful for testing integrations with simple, proprietary TCP servers.

  To use Rodeo, a listener has to be started before the test run and stopped
  afterwards.

  ## Example

      setup do
        {:ok, rodeo} = Rodeo.open(4040)

        on_exit(fn ->
          Rodeo.close(rodeo)
        end)

        {:ok, %{rodeo: rodeo}}
      end

  """
  defstruct handler: nil,
            listener: nil,
            listener_ref: nil

  @doc """
  Starts a listener process and opens a new port on the local interface.

  ## Example

      {:ok, rodeo} = Rodeo.open(5050)
  """
  def open(port, _args \\ []) do
    listener_ref = make_ref()

    with {:ok, handler} <- Rodeo.Handler.start_link(),
         {:ok, listener} <-
           :ranch.start_listener(listener_ref, :ranch_tcp, [{:port, port}], Rodeo.Protocol,
             handler: handler
           ) do
      {:ok, %Rodeo{handler: handler, listener: listener, listener_ref: listener_ref}}
    else
      error -> error
    end
  end

  @doc """
  Stops the listener for the given Rodeo instance.

  ## Example

      Rodeo.close(rodeo)
  """
  def close(%Rodeo{listener_ref: listener_ref}) do
    :ranch.stop_listener(listener_ref)
  end

  @doc """
  Creates a new stub for a specific incoming message.

  ## Example

      Rodeo.stub(rodeo, "Hello\\n", fn _ ->
        # ...
      end)
  """
  def stub(%Rodeo{handler: handler} = rodeo, match, fun \\ nil) do
    stub_id = GenServer.call(handler, {:stub, match, fun})
    {rodeo, stub_id}
  end

  @doc """
  Sends a message to the given Rodeo connection. It can be used within a stub
  in order to answer to a message, or independently, to initiate new
  communication.

  ## Example

      Rodeo.stub(rodeo, "Hello\\n", fn _ ->
        Rodeo.send(rodeo, "World\\n")
      end)

      # or

      Rodeo.send(rodeo, "Yeeehaaaa\\n")
  """
  def send(%Rodeo{handler: handler}, data) do
    GenServer.cast(handler, {:send, data})
  end

  @doc """
  Returns the call count of the given stub.

  ## Example

      stub = Rodeo.stub(rodeo, "Hey\n")
      {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 4040, active: false)
      :ok = :gen_tcp.send(socket, "Hey\n")
      assert Rodeo.call_count(stub) == 1

  """
  def call_count({%Rodeo{handler: handler}, stub_id}, opts \\ []) do
    wait = Keyword.get(opts, :wait, 5)
    Process.sleep(wait)
    GenServer.call(handler, {:call_count, stub_id})
  end
end
