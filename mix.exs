defmodule ExcellentMigrations.MixProject do
  use Mix.Project

  @source_url "https://github.com/artur-sulej/excellent_migrations"
  @version "0.1.8"

  def project do
    [
      app: :excellent_migrations,
      version: @version,
      elixir: ">= 1.11.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      preferred_cli_env: [docs: :docs]
    ]
  end

  defp package do
    [
      description: "An analysis tool for checking safety of database migrations.",
      maintainers: ["Artur Sulej"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "https://hexdocs.pm/excellent_migrations/changelog.html",
        "GitHub" => @source_url
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.5", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end
end
