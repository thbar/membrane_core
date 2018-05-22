defmodule Membrane.Mixfile do
  use Mix.Project

  def project do
    [
      app: :membrane_core,
      version: "0.0.1",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Membrane Multimedia Framework (Core)",
      package: package(),
      name: "Membrane Core",
      source_url: "https://github.com/membraneframework/membrane-core",
      preferred_cli_env: [
        espec: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      test_coverage: [tool: ExCoveralls, test_task: "espec"],
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [], mod: {Membrane, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "spec/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"]
    ]
  end

  defp deps do
    [
      {:espec, "~> 1.1", only: :test},
      {:excoveralls, "~> 0.6", only: :test},
      {:qex, "~> 0.3"},
      {:ex_doc, "~> 0.14", only: :dev}
    ]
  end
end
