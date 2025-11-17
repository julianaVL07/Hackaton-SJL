defmodule Hackathon.Cmd do
  @moduledoc "Atajo para ejecutar comandos estilo CLI con barra desde IEx."
  def slash(str) when is_binary(str), do: Hackathon.CLI.ejecutar(str)
end
