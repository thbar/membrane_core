defmodule Membrane.Mixfile do
  use Mix.Project

  @version "0.9.0"
  @source_ref "v#{@version}"

  def project do
    [
      app: :membrane_core,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Membrane Multimedia Framework (Core)",
      dialyzer: [
        flags: [:error_handling]
      ],
      package: package(),
      name: "Membrane Core",
      source_url: link(),
      docs: docs(),
      aliases: ["test.all": "do espec, test"],
      preferred_cli_env: [
        espec: :test,
        "test.all": :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      test_coverage: [tool: ExCoveralls, test_task: "test.all"],
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "spec/support", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp link do
    "https://github.com/membraneframework/membrane-core"
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "CONTRIBUTING.md", LICENSE: [title: "License"]],
      formatters: ["html"],
      source_ref: @source_ref,
      nest_modules_by_prefix: [
        Membrane.Bin,
        Membrane.Pipeline,
        Membrane.Element,
        Membrane.Element.CallbackContext,
        Membrane.Pipeline.CallbackContext,
        Membrane.Bin.CallbackContext,
        Membrane.Payload,
        Membrane.Buffer,
        Membrane.Caps,
        Membrane.Event,
        Membrane.EventProtocol,
        Membrane.Testing
      ],
      groups_for_modules: [
        Pipeline: [~r/^Membrane\.Pipeline($|\.)/, ~r/^Membrane\.(CrashGroup)($|\.)/],
        Bin: [~r/^Membrane\.Bin($|\.)/],
        Element: [
          ~r/^Membrane\.Filter($|\.)/,
          ~r/^Membrane\.Endpoint($|\.)/,
          ~r/^Membrane\.Sink($|\.)/,
          ~r/^Membrane\.Source($|\.)/,
          ~r/^Membrane\.Element($|\.)/
        ],
        Parent: [~r/^Membrane\.(Parent|ParentSpec)($|\.)/],
        Child: [~r/^Membrane\.(Child|ChildEntry)($|\.)/],
        Communication: [
          ~r/^Membrane\.(Buffer|Payload|Caps|Event|EventProtocol|Notification|Pad|KeyframeRequestEvent|RemoteStream)($|\.)/
        ],
        Logging: [~r/^Membrane\.Logger($|\.)/],
        Testing: [~r/^Membrane\.Testing($|\.)/],
        Utils: [
          ~r/^Membrane\.Clock($|\.)/,
          ~r/^Membrane\.Sync($|\.)/,
          ~r/^Membrane\.Time($|\.)/,
          ~r/^Membrane\.PlaybackState($|\.)/,
          ~r/^Membrane\.Telemetry($|\.)/,
          ~r/^Membrane\.ComponentPath($|\.)/
        ],
        Errors: [~r/Error$/]
      ]
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => link(),
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: :dev, runtime: false},
      {:espec, "~> 1.8.3", only: :test},
      {:excoveralls, "~> 0.14", only: :test},
      {:qex, "~> 0.3"},
      {:telemetry, "~> 1.0"},
      {:bunch, "~> 1.3"},
      {:ratio, "~> 2.0"}
    ]
  end
end
