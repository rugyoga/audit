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
    """
    The Audit library allows you to easily track changes to key data structutes in your code
    by decorating their updates with audit(x) like so:
      %Data{ original | foo: "bar"}
    becomes
      %Data{ audit(original) | foo: "bar"}

    This updates a hidden field, __audit_trail__ (that you need to add to your struct) with a triple
    of {filename, line, value}. By applying Audit.to_string, you can see every change made to the
    data structure as well as where in the code it was changed.
    """
  end

  defp package do
    [
      files: ~w(lib priv .formatter.exs mix.exs README* readme* LICENSE* license* CHANGELOG* changelog* src),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/rugyoga/audit"}
    ]
  end
end
