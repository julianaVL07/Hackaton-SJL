defmodule Mix.Tasks.Hackathon do
  use Mix.Task

  @moduledoc """
  Tarea personalizada de Mix que permite ejecutar comandos del CLI del sistema
  Hackathon directamente desde la terminal.
  """

  @shortdoc "Ejecuta comandos CLI del hackathon (ej: mix hackathon /teams)"
  def run(args) do
    # Asegura que la aplicación y sus dependencias estén levantadas
    Application.ensure_all_started(:hackathon)

    # Unimos todos los parámetros en un solo comando
    comando = Enum.join(args, " ")

    case comando do
      "" ->
        # Mensaje mostrado si no se envió ningún comando
        Mix.shell().info("Proporciona un comando. Ej: mix hackathon /teams")

      other ->
        # Delegamos la ejecución al CLI del sistema
        _ = Hackathon.CLI.ejecutar(other)
    end
  end
end
