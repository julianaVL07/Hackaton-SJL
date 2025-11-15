@doc """
Módulo encargado de ejecutar pruebas de carga para medir el rendimiento
global del sistema bajo múltiples operaciones concurrentes.
"""
defmodule LoadTest do
  @moduledoc """
  Pruebas de carga para evaluar el rendimiento del sistema
  con múltiples equipos y participantes concurrentes.
  """

  @doc """
  Función principal que coordina la creación de equipos, participantes,
  proyectos y mensajes de chat, midiendo tiempos de ejecución.
  """
  def simular_hackathon(num_equipos, participantes_por_equipo) do
    IO.puts("\n INICIANDO PRUEBA DE CARGA")
    IO.puts("  Equipos: #{num_equipos}")
    IO.puts("  Participantes por equipo: #{participantes_por_equipo}")
    IO.puts("  Total de participantes: #{num_equipos * participantes_por_equipo}\n")

    inicio = System.monotonic_time(:millisecond)
  end
end
