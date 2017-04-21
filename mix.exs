defmodule SessionHeaderPlug.Mixfile do
  use Mix.Project

  def project do
    [
      app: :session_header_plug,
      build_embedded: Mix.env === :prod,
      deps: deps(),
      description: "A plug to handle session headers and session stores",
      docs: docs(),
      elixir: "~> 1.4",
      name: "SessionHeaderPlug",
      package: package(),
      start_permanent: Mix.env === :prod,
      version: "0.1.0",
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.15", only: :dev, runtime: false},
      {:plug, "~> 1.3.5"},
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
    ]
  end

  defp package do
    [
      licenses: ["BSD 2-Clause License"],
      links: %{
        "GitHub" => "https://github.com/endersstocker/session-header-plug",
      },
      maintainers: ["Bryan Enders"],
    ]
  end
end
