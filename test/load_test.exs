defmodule LoadTest do
  @moduledoc """
  Utilidades para ejecutar pruebas de carga del sistema Hackathon.

  La prueba simula:
    - Creación masiva de equipos
    - Registro concurrente de participantes
    - Creación de proyectos
    - Envío de mensajes en chats

  Todo se ejecuta en paralelo para medir rendimiento.
  """

  @doc """
  Ejecuta una prueba de carga completa.

  Recibe:
    - `num_equipos`: cantidad de equipos a crear
    - `participantes_por_equipo`: usuarios a registrar en cada equipo

  Mide tiempos parciales y totales.
  """
  def simular_hackathon(num_equipos, participantes_por_equipo) do
    IO.puts("\n INICIANDO PRUEBA DE CARGA")
    IO.puts("  Equipos: #{num_equipos}")
    IO.puts("  Participantes por equipo: #{participantes_por_equipo}")
    IO.puts("  Total de participantes: #{num_equipos * participantes_por_equipo}\n")

    inicio = System.monotonic_time(:millisecond)

    equipos_task =
      Task.async(fn -> crear_equipos_paralelo(num_equipos) end)

    equipos = Task.await(equipos_task, 30_000)
    tiempo_equipos = System.monotonic_time(:millisecond) - inicio
    IO.puts(" #{length(equipos)} equipos creados en #{tiempo_equipos}ms")

    inicio_participantes = System.monotonic_time(:millisecond)
    agregar_participantes_paralelo(equipos, participantes_por_equipo)
    tiempo_participantes = System.monotonic_time(:millisecond) - inicio_participantes
    IO.puts(" Participantes agregados en #{tiempo_participantes}ms")

    inicio_proyectos = System.monotonic_time(:millisecond)
    crear_proyectos_paralelo(equipos)
    tiempo_proyectos = System.monotonic_time(:millisecond) - inicio_proyectos
    IO.puts(" Proyectos creados en #{tiempo_proyectos}ms")

    inicio_chat = System.monotonic_time(:millisecond)
    simular_chat_paralelo(equipos, 10)
    tiempo_chat = System.monotonic_time(:millisecond) - inicio_chat
    IO.puts(" Mensajes enviados en #{tiempo_chat}ms")

    tiempo_total = System.monotonic_time(:millisecond) - inicio

    IO.puts("\n RESUMEN:")
    IO.puts("  Tiempo total: #{tiempo_total}ms")
    IO.puts("  Promedio por equipo: #{div(tiempo_total, num_equipos)}ms")
    IO.puts("  Equipos/segundo: #{Float.round(num_equipos / (tiempo_total / 1000), 2)}")

    :ok
  end

  @doc """
  Crea varios equipos en paralelo usando `Task.async_stream`.

  Retorna una lista con los nombres de los equipos creados.
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
  Agrega `num_participantes` a cada equipo en paralelo.
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

  @doc """
  Crea un proyecto para cada equipo en paralelo.
  """
  defp crear_proyectos_paralelo(equipos) do
    categorias = [:social, :ambiental, :educativo]

    equipos
    |> Task.async_stream(
      fn equipo ->
        categoria = Enum.random(categorias)
        descripcion = "Proyecto innovador de #{equipo}"
        Hackathon.crear_proyecto(equipo, descripcion, categoria)
      end,
      max_concurrency: 50,
      timeout: 10_000
    )
    |> Stream.run()
  end

  @doc """
  Simula actividad de chat para cada equipo, enviando varios mensajes en paralelo.
  """
  defp simular_chat_paralelo(equipos, mensajes_por_equipo) do
    equipos
    |> Task.async_stream(
      fn equipo ->
        Hackathon.crear_sala(equipo)

        1..mensajes_por_equipo
        |> Enum.each(fn i ->
          autor = "Usuario#{i}"
          mensaje = "Mensaje de prueba #{i}"
          Hackathon.enviar_mensaje(equipo, autor, mensaje)
        end)
      end,
      max_concurrency: 50,
      timeout: 10_000
    )
    |> Stream.run()
  end
end
