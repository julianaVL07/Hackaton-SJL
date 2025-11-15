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



    @doc """
    Agrega participantes a cada equipo de manera paralela.
    Mide el tiempo necesario para completar el proceso.
    """
    inicio_participantes = System.monotonic_time(:millisecond)

    agregar_participantes_paralelo(equipos, participantes_por_equipo)

    tiempo_participantes = System.monotonic_time(:millisecond) - inicio_participantes

    IO.puts("Participantes agregados en #{tiempo_participantes}ms")

    @doc """
    Crea un proyecto por equipo utilizando concurrencia,
    asignando categorías aleatorias y midiendo el tiempo.
    """
    inicio_proyectos = System.monotonic_time(:millisecond)

    crear_proyectos_paralelo(equipos)

    tiempo_proyectos = System.monotonic_time(:millisecond) - inicio_proyectos

    IO.puts("Proyectos creados en #{tiempo_proyectos}ms")

    #Comit 6 - Simular mensajes de chat en paralelo
    @doc """
    Simula la actividad del chat enviando múltiples mensajes por equipo
    a través de procesos concurrentes.
    """
    inicio_chat = System.monotonic_time(:millisecond)

    simular_chat_paralelo(equipos, 10)

    tiempo_chat = System.monotonic_time(:millisecond) - inicio_chat

    IO.puts("Mensajes enviados en #{tiempo_chat}ms")

    @doc """
    Calcula y muestra un resumen general del rendimiento, incluyendo
    tiempo total, promedio por equipo y equipos procesados por segundo.
    """
    tiempo_total = System.monotonic_time(:millisecond) - inicio

    IO.puts("\nRESUMEN:")
    IO.puts("  Tiempo total: #{tiempo_total}ms")
    IO.puts("  Promedio por equipo: #{div(tiempo_total, num_equipos)}ms")
    IO.puts("  Equipos/segundo: #{Float.round(num_equipos / (tiempo_total / 1000), 2)}")

    :ok
  end

  @doc """
  Crea varios equipos en paralelo asignando temas aleatorios.
  Utiliza Task.async_stream para maximizar eficiencia.
  """
  defp crear_equipos_paralelo(num_equipos) do
    1..num_equipos
    |> Task.async_stream(
      fn i ->
        nombre = "Equipo_#{i}"
        tema = Enum.random(["IA", "Blockchain", "IoT", "Web3", "Cloud"])

        case Hackathon.crear_equipo(nombre, tema) do
          {:ok, equipo} -> equipo.nombre
          _ -> nil
        end
      end,
      max_concurrency: 50,
      timeout: 10_000
    )
    |> Enum.map(fn {:ok, nombre} -> nombre end)
    |> Enum.reject(&is_nil/1)
  end

   @doc """
  Agrega múltiples participantes a cada equipo de manera concurrente.
  Cada participante recibe un email único basado en su equipo.
  """
  defp agregar_participantes_paralelo(equipos, num_participantes) do
    equipos
    |> Task.async_stream(
      fn equipo ->
        1..num_participantes
        |> Enum.each(fn j ->
          nombre = "Participante_#{j}"
          email = "participante_#{j}_#{equipo}@test.com"
          Hackathon.agregar_participante(equipo, nombre, email)
        end)
      end,
      max_concurrency: 50,
      timeout: 10_000
    )
    |> Stream.run()
  end

end
