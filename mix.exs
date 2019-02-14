defmodule Rodeo.MixProject do
  use Mix.Project

  def project do
    [
      app: :rodeo,
      version: "0.1.0",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description:
        "Rodeo provides a convenient way for creating a plain TCP mock server. This is useful for testing integrations with simple, proprietary TCP servers.",
      package: [
        name: "rodeo_tcp",
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/suitepad-gmbh/rodeo"}
      ],
      deps: deps(),
      name: "rodeo_tcp",
      source_url: "https://github.com/suitepad-gmbh/rodeo"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ranch]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ranch, "~> 1.7"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
