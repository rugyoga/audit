defmodule Audit.MixProject do
  use Mix.Project

  def project do
    [
      app: :audit,
      version: "0.1.0",
      elixir: "~> 1.13",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Audit",
      source_url: "https://github.com/rugyoga/audit"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mock, "~> 0.3.7", only: [:ci, :test]},
    ]
  end

  defp description do
    "The Audit library allows you to easily track changes to key data structutes in your code."
  end

  defp package do
    [
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/rugyoga/audit"}
    ]
  end
end
