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



    @doc """
    Crea equipos concurrentemente utilizando `Task.async_stream`, retornando
    la lista de equipos creados y midiendo su tiempo de ejecución.
    """
    equipos_task =
      Task.async(fn ->
        crear_equipos_paralelo(num_equipos)
      end)

    equipos = Task.await(equipos_task, 30_000)
    tiempo_equipos = System.monotonic_time(:millisecond) - inicio

    IO.puts(" #{length(equipos)} equipos creados en #{tiempo_equipos}ms")
  end

end
