defmodule Hackathon.MixProject do
  @moduledoc """
  Configuración principal del proyecto Hackathon.
  Forma parte de la estructura generada por Mix para gestionar compilación,
  dependencias y ejecución del sistema.
  """

  use Mix.Project

  @doc """
  Define la configuración general del proyecto.
  """
  def project do
    [
      app: :hackathon,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  @doc """
  Configura la aplicación OTP al momento de ejecutarse.
  """
  def application do
    [
      extra_applications: [:logger],
      mod: {Hackathon.Application, []}
    ]
  end

  @doc """
  Lista de dependencias externas requeridas por el proyecto.
  """
  defp deps do
    [
      {:phoenix_pubsub, "~> 2.1"},
      {:jason, "~> 1.4"}
    ]
  end
end
