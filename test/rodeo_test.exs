defmodule RodeoTest do
  use ExUnit.Case
  doctest Rodeo

  setup do
    {:ok, rodeo} = Rodeo.open(4040)

    on_exit(fn ->
      Rodeo.close(rodeo)
    end)

    {:ok, %{rodeo: rodeo}}
  end

  test "greets the world", %{rodeo: rodeo} do
    Rodeo.stub(rodeo, "Hello\n", fn _ ->
      Rodeo.send(rodeo, "World\n")
    end)

    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 4040, active: false)
    :ok = :gen_tcp.send(socket, "Hello\n")
    {:ok, reply} = :gen_tcp.recv(socket, 0, 1000)

    assert reply == 'World\n'
  end

  test "sending data", %{rodeo: rodeo} do
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, 4040, active: false)
    Process.sleep(100)
    Rodeo.send(rodeo, "Yeeehaaaa\n")
    {:ok, reply} = :gen_tcp.recv(socket, 0, 1000)
    assert reply == 'Yeeehaaaa\n'
  end
end
