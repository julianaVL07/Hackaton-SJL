defmodule Hackathon.CLI do
  @moduledoc """
  Interfaz de línea de comandos para el sistema de hackathon.
  """

  alias Hackathon.Teams.TeamManager
  alias Hackathon.Projects.ProjectManager
  alias Hackathon.Chat.ChatServer
  alias Hackathon.Mentors.MentorManager
  alias Hackathon.Storage

  @doc """
  Ejecuta un comando en formato string.
  """
  def ejecutar(comando) when is_binary(comando) do
    comando
    |> String.trim()
    |> String.split(" ", parts: 4)
    |> procesar_comando()
  end

  @doc """
  Alias simple para ejecutar comandos.
  """
  def cmd(str), do: ejecutar(str)

  @doc """
  Alias para ejecutar comandos desde IEx.
  """
  def c(cmd), do: ejecutar(cmd)

  @doc """
  Alias para ejecutar comandos.
  """
  def run(cmd), do: ejecutar(cmd)

  @doc """
  Crea una sala de chat rápidamente.
  """
  def chat_create(sala), do: ejecutar("/chat_create #{sala}")

  @doc """
  Muestra una sala de chat.
  """
  def chat(sala), do: ejecutar("/chat #{sala}")

  @doc """
  Envía un mensaje a una sala.
  """
  def chat_send(sala, autor, mensaje), do: ejecutar("/chat_send #{sala} #{autor} #{mensaje}")

  @doc """
  Procesa comandos relacionados con equipos.
  """
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

  @doc """
  Muestra información del proyecto de un equipo.
  """
  defp procesar_comando(["/project", nombre_equipo]) do
    case ProjectManager.obtener_proyecto(nombre_equipo) do
      {:ok, proyecto} ->
        IO.puts("\n PROYECTO: #{proyecto.nombre_equipo}\n")
        IO.puts("  Descripción: #{proyecto.descripcion}")
        IO.puts("  Categoría: #{proyecto.categoria}")
        IO.puts("  Estado: #{proyecto.estado}")
        IO.puts("  Avances: #{length(proyecto.avances)}")

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

  @doc """
  Agrega un participante a un equipo.
  """
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

  @doc """
  Muestra mensajes de una sala de chat.
  """
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
        IO.puts("\n La sala '#{sala}' no existe. Crea una con:\n  /chat_create #{sala}\n")
    end

    :ok
  end

  @doc """
  Crea una sala de chat.
  """
  defp procesar_comando(["/chat_create", sala]) do
    case ChatServer.crear_sala(sala) do
      {:ok, ^sala} ->
        IO.puts("\n Sala creada: #{sala}\n")

      {:error, :sala_existente} ->
        IO.puts("\n La sala '#{sala}' ya existe.\n")

      other ->
        IO.puts("\n Error al crear la sala: #{inspect(other)}\n")
    end

    :ok
  end

  @doc """
  Envía un mensaje a una sala de chat.
  """
  defp procesar_comando(["/chat_send", sala, autor, contenido]) do
    ChatServer.enviar_mensaje(sala, autor, contenido)
    IO.puts("\n Mensaje enviado a '#{sala}'.\n")
    :ok
  end

  @doc """
  Lista todos los mentores disponibles.
  """
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

  @doc """
  Guarda el estado persistido en almacenamiento.
  """
  defp procesar_comando(["/persist_save"]) do
    Storage.persist_state()
    IO.puts("\n Estado persistido.\n")
    :ok
  end

  @doc """
  Muestra la información del estado persistido.
  """
  defp procesar_comando(["/persist_info"]) do
    info = Storage.persist_info()

    IO.puts("""
    \n Persistencia:
      Equipos: #{info.equipos}
      Proyectos: #{info.proyectos}
      Mentores: #{info.mentores}
      Salas chat: #{info.salas_chat}\n
    """)

    :ok
  end

  @doc """
  Muestra información del clúster.
  """
  defp procesar_comando(["/cluster_info"]) do
    Hackathon.Cluster.info()
    :ok
  end

  @doc """
  Conecta un nodo remoto al clúster.
  """
  defp procesar_comando(["/cluster_connect", nodo_remoto]) do
    Hackathon.Cluster.conectar(nodo_remoto)
    :ok
  end

  @doc """
  Lista los nodos conectados al clúster.
  """
  defp procesar_comando(["/cluster_nodes"]) do
    nodos = Hackathon.Cluster.listar_nodos()

    IO.puts("\n NODOS ACTIVOS:\n")
    Enum.each(nodos, fn nodo ->
      marca = if nodo == Node.self(), do: " ", else: "  "
      IO.puts("#{marca} #{nodo}")
    end)
    IO.puts("")

    :ok
  end

  @doc """
  Hace ping a los nodos del clúster.
  """
  defp procesar_comando(["/cluster_ping"]) do
    Hackathon.Cluster.ping_cluster()
    :ok
  end

  @doc """
  Muestra la lista de comandos disponibles.
  """
  defp procesar_comando(["/help"]) do
    IO.puts("""
    COMANDOS DISPONIBLES:

      ===  CLUSTER DISTRIBUIDO ===
      /cluster_info
        Información del cluster (nodos, cookie, etc.)

      /cluster_connect <nodo>
        Conectar a otro nodo
        Ejemplo: /cluster_connect hackathon@192.168.1.20

      /cluster_nodes
        Lista todos los nodos activos

      /cluster_ping
        Verifica conectividad con todos los nodos

      ===  EQUIPOS ===
      /teams
        Lista todos los equipos

      /join <equipo> <nombre> <email>
        Únete a un equipo

      ===  PROYECTOS ===
      /project <nombre_equipo>
        Información del proyecto

      ===  CHAT ===
      /chat <sala>
        Historial de una sala

      /chat_create <sala>
        Crear sala

      /chat_send <sala> <autor> <mensaje>
        Enviar mensaje

      ===  MENTORES ===
      /mentors
        Lista mentores

      ===  PERSISTENCIA ===
      /persist_save
        Guardar estado

      /persist_info
        Info de persistencia

      ===  AYUDA ===
      /help
        Esta ayuda

    """)

    :ok
  end

  @doc """
  Maneja comandos desconocidos.
  """
  defp procesar_comando(_) do
    IO.puts("\n Comando no reconocido. Escribe /help para ver los comandos disponibles.\n")
    :error
  end

  @doc """
  Inicia el modo interactivo del CLI.
  """
  def iniciar_modo_interactivo do
    Storage.bootstrap()

    IO.puts("""
     SISTEMA DE HACKATHON COLABORATIVA

    Estado cargado (si existía). Usa /persist_save para guardar.
    Escribe /help para ver comandos. 'salir' para terminar.
    """)

    loop_interactivo()
  end

  @doc """
  Loop principal que recibe comandos del usuario.
  """
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

  @doc """
  Maneja la creación de equipos mediante entrada interactiva.
  """
  def handle_command("/create_team", state) do
    attrs = prompt_team_creation()

    case TeamManager.crear_equipo(attrs.nombre, attrs.tema) do
      {:ok, team} ->
        Enum.each(attrs.participantes, fn p ->
          _ = TeamManager.agregar_participante(team.nombre, p.nombre, p.email)
        end)

        IO.puts(" Equipo creado: #{team.nombre}")

      {:error, reason} ->
        IO.puts(" No se pudo crear el equipo: #{inspect(reason)}")

      other ->
        IO.puts(" Respuesta inesperada: #{inspect(other)}")
    end

    state
  end

  @doc """
  Solicita los datos necesarios para crear un equipo.
  """
  defp prompt_team_creation do
    IO.puts("\nCreación de equipo")
    nombre = prompt_non_empty("Nombre del equipo: ")
    tema = prompt_non_empty("Tema del equipo: ")
    n = prompt_integer("Número de participantes (0 o más): ")

    participantes =
      Enum.map(1..n, fn i ->
        IO.puts("Participante #{i}:")
        p_nombre = prompt_non_empty("- Nombre: ")
        p_email = prompt_non_empty("- Email: ")
        %{nombre: p_nombre, email: p_email}
      end)

    %{nombre: nombre, tema: tema, participantes: participantes}
  end

  @doc """
  Solicita un valor no vacío.
  """
  defp prompt_non_empty(label) do
    value =
      label
      |> IO.gets()
      |> to_string()
      |> String.trim()

    if value == "" do
      IO.puts("El valor no puede estar vacío.")
      prompt_non_empty(label)
    else
      value
    end
  end

  @doc """
  Solicita al usuario un número entero válido.
  """
  defp prompt_integer(label) do
    case label |> IO.gets() |> to_string() |> String.trim() |> Integer.parse() do
      {n, _} when n >= 0 ->
        n

      _ ->
        IO.puts("Introduce un número entero mayor o igual a 0.")
        prompt_integer(label)
    end
  end

  @doc """
  Crea múltiples equipos y salas para probar escalabilidad.
  """
  def test_scalabilidad do
    for i <- 1..20 do
      _ = Hackathon.Teams.TeamManager.crear_equipo("team#{i}", "tema#{i}")
      _ = Hackathon.Chat.ChatServer.crear_sala("equipo:team#{i}")
      _ = Hackathon.Chat.ChatServer.enviar_mensaje("equipo:team#{i}", "bot", "ping #{i}")
    end
    :ok
  end

  @doc """
  Prueba la tolerancia a fallos del chat matando su proceso.
  """
  def test_tolerancia_fallos do
    pid = Process.whereis(Hackathon.Chat.ChatServer)
    if pid, do: Process.exit(pid, :kill)
    :timer.sleep(100)
    %{nuevo_pid: Process.whereis(Hackathon.Chat.ChatServer)}
  end

  @doc """
  Muestra información del clúster y salas.
  """
  def test_cluster do
    %{
      cluster: Hackathon.Storage.cluster_info(),
      salas_vivas: Hackathon.Chat.ChatServer.listar_salas(),
      salas_persistidas: Hackathon.Storage.listar_salas_persistidas()
    }
  end

  @doc """
  Demuestra el orden de los mensajes enviados en una sala.
  """
  def demo_orden_mensajes do
    _ = Hackathon.Chat.ChatServer.crear_sala("general")
    _ = Hackathon.Chat.ChatServer.enviar_mensaje("general","A","uno")
    _ = Hackathon.Chat.ChatServer.enviar_mensaje("general","B","dos")
    _ = Hackathon.Chat.ChatServer.enviar_mensaje("general","C","tres")
    Hackathon.Chat.ChatServer.obtener_historial("general")
  end
end
