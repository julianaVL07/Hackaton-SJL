defmodule Hackathon.CLI do
  @moduledoc """
  Módulo encargado de proporcionar una interfaz de línea de comandos (CLI) para el
  sistema de hackathon
  """

  alias Hackathon.Teams.TeamManager
  alias Hackathon.Projects.ProjectManager
  alias Hackathon.Chat.ChatServer
  alias Hackathon.Mentors.MentorManager

  @doc """
  Ejecuta un comando recibido como cadena. El comando es normalizado (sin espacios
  sobrantes) y dividido en partes para su posterior interpretación.
  """
  def ejecutar(comando) when is_binary(comando) do
    comando
    |> String.trim()
    |> String.split(" ", parts: 4) # Permite comandos con 1 a 4 parámetros.
    |> procesar_comando()
  end

  @doc
  # Manejador del comando `/teams`. Lista todos los equipos registrados.
  defp procesar_comando(["/teams"]) do
    equipos = TeamManager.listar_equipos()

    if Enum.empty?(equipos) do
      IO.puts("\n No hay equipos registrados aún.\n")
    else
      IO.puts("\n EQUIPOS REGISTRADOS:\n")

      Enum.each(equipos, fn equipo ->
        IO.puts("  • #{equipo.nombre}")
        IO.puts("    Tema: #{equipo.tema}")
        IO.puts("    Participantes: #{length(equipo.participantes)}")
        IO.puts("")
      end)
    end

    :ok
  end

  @doc
  # Manejador del comando `/project <nombre_equipo>`.
  # Muestra la información del proyecto asociado al equipo.
  defp procesar_comando(["/project", nombre_equipo]) do
    case ProjectManager.obtener_proyecto(nombre_equipo) do
      {:ok, proyecto} ->
        IO.puts("\n PROYECTO: #{proyecto.nombre_equipo}\n")
        IO.puts("  Descripción: #{proyecto.descripcion}")
        IO.puts("  Categoría: #{proyecto.categoria}")
        IO.puts("  Estado: #{proyecto.estado}")
        IO.puts("  Avances: #{length(proyecto.avances)}")

        # Si existen avances, mostrar los 3 más recientes.
        unless Enum.empty?(proyecto.avances) do
          IO.puts("\n   Últimos avances:")
          proyecto.avances
          |> Enum.take(3)
          |> Enum.each(fn avance ->
            IO.puts("    - #{avance}")
          end)
        end

        IO.puts("")

      {:error, :proyecto_no_encontrado} ->
        IO.puts("\n No se encontró proyecto para el equipo '#{nombre_equipo}'.\n")
    end

    :ok
  end


  # Manejador del comando `/join <equipo> <nombre> <email>`.
  # Permite a un participante unirse a un equipo existente.
  defp procesar_comando(["/join", nombre_equipo, nombre, email]) do
    case TeamManager.agregar_participante(nombre_equipo, nombre, email) do
      {:ok, _equipo} ->
        IO.puts("\n ¡Bienvenido #{nombre}! Te has unido al equipo '#{nombre_equipo}'.\n")

      {:error, :equipo_no_encontrado} ->
        IO.puts("\n El equipo '#{nombre_equipo}' no existe.\n")

      {:error, :participante_duplicado} ->
        IO.puts("\n El email '#{email}' ya está registrado en este equipo.\n")
    end

    :ok
  end


  # Manejador del comando `/chat <sala>`.
  # Muestra el historial de mensajes de una sala de chat.
  defp procesar_comando(["/chat", sala]) do
    case ChatServer.obtener_historial(sala) do
      {:ok, mensajes} ->
        if Enum.empty?(mensajes) do
          IO.puts("\n No hay mensajes en la sala '#{sala}' aún.\n")
        else
          IO.puts("\n CHAT: #{sala}\n")

          Enum.each(mensajes, fn mensaje ->
            tiempo = Calendar.strftime(mensaje.timestamp, "%H:%M")
            IO.puts("  [#{tiempo}] #{mensaje.autor}: #{mensaje.contenido}")
          end)

          IO.puts("")
        end

      {:error, :sala_no_encontrada} ->
        IO.puts("\n La sala '#{sala}' no existe.\n")
    end

    :ok
  end

@doc false
  # Manejador del comando /mentors. Lista todos los mentores registrados.
  defp procesar_comando(["/mentors"]) do
    mentores = MentorManager.listar_mentores()

    if Enum.empty?(mentores) do
      IO.puts("\n No hay mentores registrados aún.\n")
    else
      IO.puts("\n MENTORES DISPONIBLES:\n")

      Enum.each(mentores, fn mentor ->
        IO.puts("  • #{mentor.nombre}")
        IO.puts("    Especialidad: #{mentor.especialidad}")
        IO.puts("    ID: #{mentor.id}")
        IO.puts("")
      end)
    end

    :ok
  end


  # Manejador del comando /help. Muestra la guía de ayuda.
  defp procesar_comando(["/help"]) do
    IO.puts("""

     COMANDOS DISPONIBLES:

      /teams
        Lista todos los equipos registrados

      /project <nombre_equipo>
        Muestra información del proyecto de un equipo

      /join <equipo> <nombre> <email>
        Únete a un equipo existente

      /chat <sala>
        Muestra el historial de una sala de chat

      /mentors
        Lista todos los mentores disponibles

      /help
        Muestra esta ayuda

    """)

    :ok
  end


  # Manejador para comandos no reconocidos.
  defp procesar_comando(_) do
    IO.puts("\n Comando no reconocido. Escribe /help para ver los comandos disponibles.\n")
    :error
  end

  @doc """
  Inicia el modo interactivo de la CLI, mostrando un prompt en la consola
  y permitiendo ingresar comandos hasta escribir salir.
  """
  def iniciar_modo_interactivo do
    IO.puts("""

     SISTEMA DE HACKATHON COLABORATIVA

    Escribe /help para ver los comandos disponibles.
    Escribe 'salir' para terminar.

    """)

    loop_interactivo()
  end


  # Ciclo principal del modo interactivo.
  defp loop_interactivo do
    entrada = IO.gets("hackathon> ") |> String.trim()

    case entrada do
      "salir" ->
        IO.puts("\n ¡Hasta pronto!\n")
        :ok

      "" ->
        loop_interactivo()

      comando ->
        ejecutar(comando)
        loop_interactivo()
    end
  end

end
