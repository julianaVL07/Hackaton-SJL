defmodule Hackathon.MixProject do
  @moduledoc """
  Configuración principal del proyecto Hackathon:
  nombre, versión, dependencias y módulo de arranque.
  """

  use Mix.Project

  def project do
    [
      app: :hackathon,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  @doc "Define la aplicación OTP y su módulo supervisor."
  def application do
    [
      extra_applications: [:logger],
      mod: {Hackathon.Application, []}
    ]
  end

  @doc "Dependencias del proyecto."
  defp deps do
    [
      {:phoenix_pubsub, "~> 2.1"},
      {:jason, "~> 1.4"}
    ]
  end
end
