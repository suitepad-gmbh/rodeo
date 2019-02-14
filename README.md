# Rodeo

Rodeo provides a convenient way for creating a plain TCP mock server. This is
useful for testing integrations with simple, proprietary TCP servers.

## Installation

Add `rodeo` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rodeo, "~> 0.1.0", hex: :rodeo_tcp}
  ]
end
```

## Usage

To use Rodeo, open a socket in the setup of your test, and make sure to close it
again afterwards.

```elixir
setup do
  {:ok, rodeo} = Rodeo.open(4040)

  on_exit(fn ->
    Rodeo.close(rodeo)
  end)

  {:ok, %{rodeo: rodeo}}
end
```

Now you can use `stub/3` and `send/2` for stubbing requests and sending data to
the connection.

## Example

```elixir
defmodule FooTest do
  use ExUnit.Case

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
end
```

## License

This software is licensed under [the MIT license](LICENSE).
