defmodule EigenlayerEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :eigenlayer_ex,
      version: "0.1.0",
      elixir: "~> 1.17",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # to-do bump eth_wallet deps
  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ethers, "~> 0.5.2"},
      {:dotenv, "~> 3.1"},
      {:ex_secp256k1, "~> 0.7.3"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
