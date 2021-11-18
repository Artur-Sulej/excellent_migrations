defmodule ExcellentMigrations.MixProject do
  use Mix.Project

  def project do
    [
      app: :excellent_migrations,
      version: "0.1.0",
      elixir: ">= 1.7.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "An analysis tool for checking safety of database migrations.",
      package: package(),
      source_url: "https://github.com/artur-sulej/excellent_migrations",
      docs: [
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"]
      ]
    ]
  end

  defp package do
    [
      maintainers: ["Artur Sulej"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/artur-sulej/excellent_migrations",
        "Changelog" =>
          "https://github.com/artur-sulej/excellent_migration/blob/master/CHANGELOG.md"
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
      {:ex_doc, "~> 0.25", only: :dev, runtime: false}
    ]
  end
end
