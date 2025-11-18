defmodule Hackathon.Storage do
  @moduledoc """
  Módulo responsable de la persistencia global del sistema Hackathon.
  """

  @base_dir Path.join(Application.app_dir(:hackathon, "priv"), "storage")
  @chat_dir Path.join(@base_dir, "chat")

  # API PRINCIPAL


  @doc """
  Inicializa el sistema de almacenamiento al arrancar la aplicación.
  """
  def bootstrap do
    ensure_dirs()
    cargar_equipos()
    cargar_mentores()
    cargar_proyectos()
    cargar_chats()
    :ok
  end

  @doc """
  Persistencia completa del estado del runtime.
  """
  def persist_state do
    ensure_dirs()

    equipos_map =
      safe_list(fn -> Hackathon.Teams.TeamManager.listar_equipos() end)
      |> Enum.reduce(%{}, fn t, acc -> Map.put(acc, t.nombre, t) end)

    mentores_map =
      safe_list(fn -> Hackathon.Mentors.MentorManager.listar_mentores() end)
      |> Enum.reduce(%{}, fn m, acc ->
        key = if Map.has_key?(m, :id), do: m.id, else: m.nombre
        Map.put(acc, key, m)
      end)

    proyectos_map =
      case safe(fn -> Hackathon.Projects.ProjectManager.listar_proyectos() end) do
        list when is_list(list) ->
          Enum.reduce(list, %{}, fn p, acc ->
            key =
              if Map.has_key?(p, :nombre_equipo), do: p.nombre_equipo, else: Map.get(p, :id, p)

            Map.put(acc, key, p)
          end)

        _ ->
          # Estado mínimo en caso de fallo
          %{
            "default" => %{
              id: "default",
              nombre_equipo: "Equipo Sin Nombre",
              integrantes: [],
              descripcion: "Proyecto sin descripción",
              estado: "pendiente"
            }
          }
      end

    guardar_equipos(equipos_map)
    guardar_mentores(mentores_map)
    guardar_proyectos(proyectos_map)
    guardar_chats()
    :ok
  end

  @doc """
  Devuelve información estadística de los archivos persistidos:
  """
  def persist_info do
    ensure_dirs()

    equipos = load_etf("teams.etf") || %{}
    proyectos = load_etf("projects.etf") || %{}
    mentores = load_etf("mentors.etf") || %{}
    salas = load_etf(Path.join("chat", "index.etf")) || []

    %{
      equipos: map_size(equipos),
      proyectos: map_size(proyectos),
      mentores: map_size(mentores),
      salas_chat: length(salas)
    }
  end

  @doc """
  Elimina de manera completa todos los archivos persistidos en priv/storage.
  Se utiliza en pruebas que requieren estado limpio.
  """
  def clear_all do
    try do
      File.rm_rf!(@base_dir)
    rescue
      _ -> :ok
    end

    ensure_dirs()
    :ok
  end


  # CARGA DESDE DISCO (USADO EN BOOTSTRAP Y POR LOS MANAGERS)


  @doc """
  Carga los equipos desde su archivo ETF.
  """
  def cargar_equipos do
    case load_etf("teams.etf") do
      nil -> {:ok, %{}}
      %{} = map -> {:ok, map}
      list when is_list(list) ->
        {:ok, Enum.reduce(list, %{}, fn t, acc -> Map.put(acc, t.nombre, t) end)}
      _ -> {:ok, %{}}
    end
  rescue
    _ -> {:ok, %{}}
  end

  @doc """
  Carga mentores desde disco aplicando las mismas reglas de compatibilidad
  que cargar_equipos/0.
  """
  def cargar_mentores do
    case load_etf("mentors.etf") do
      nil -> {:ok, %{}}
      %{} = map -> {:ok, map}
      list when is_list(list) ->
        {:ok,
         Enum.reduce(list, %{}, fn m, acc ->
           key = if Map.has_key?(m, :id), do: m.id, else: m.nombre
           Map.put(acc, key, m)
         end)}
      _ -> {:ok, %{}}
    end
  rescue
    _ -> {:ok, %{}}
  end

  @doc """
  Carga proyectos desde disco, soporta versiones anteriores y valores faltantes.
  """
  def cargar_proyectos do
    case load_etf("projects.etf") do
      nil -> {:ok, %{}}
      %{} = map -> {:ok, map}
      list when is_list(list) ->
        {:ok,
         Enum.reduce(list, %{}, fn p, acc ->
           key = if Map.has_key?(p, :nombre_equipo), do: p.nombre_equipo, else: Map.get(p, :id, p)
           Map.put(acc, key, p)
         end)}
      _ -> {:ok, %{}}
    end
  rescue
    _ -> {:ok, %{}}
  end


  # CARGA DE CHATS Y RECONSTRUCCIÓN DEL CHATSERVER
  defp cargar_chats do
    salas = load_etf(Path.join("chat", "index.etf")) || []

    Enum.each(salas, fn sala ->
      mensajes = load_file(Path.join(@chat_dir, "#{sala}.etf")) || []
      _ = safe(fn -> Hackathon.Chat.ChatServer.crear_sala(sala) end)

      mensajes = Enum.reverse(mensajes)

      Enum.each(mensajes, fn m ->
        safe(fn -> Hackathon.Chat.ChatServer.enviar_mensaje(sala, m.autor, m.contenido) end)
      end)
    end)

    :ok
  end


  # PERSISTENCIA A DISCO (LLAMADO POR LOS MANAGERS)


  @doc """
  Guarda todos los equipos en teams.etf.
  Acepta mapas o listas de estructuras.
  """
  def guardar_equipos(equipos) when is_map(equipos) do
    write_etf("teams.etf", equipos)
    :ok
  end

  def guardar_equipos(equipos) when is_list(equipos) do
    map = Enum.reduce(equipos, %{}, fn t, acc -> Map.put(acc, t.nombre, t) end)
    guardar_equipos(map)
  end

  @doc """
  Guarda los mentores en mentors.etf.
  Admite lista o mapa, normaliza claves usando id o nombre.
  """
  def guardar_mentores(mentores) when is_map(mentores) do
    write_etf("mentors.etf", mentores)
    :ok
  end

  def guardar_mentores(mentores) when is_list(mentores) do
    map =
      Enum.reduce(mentores, %{}, fn m, acc ->
        key = if Map.has_key?(m, :id), do: m.id, else: m.nombre
        Map.put(acc, key, m)
      end)

    guardar_mentores(map)
  end

  @doc """
  Guarda los proyectos en projects.etf, normalizando claves.
  """
  def guardar_proyectos(proyectos) when is_map(proyectos) do
    write_etf("projects.etf", proyectos)
    :ok
  end

  def guardar_proyectos(proyectos) when is_list(proyectos) do
    map =
      Enum.reduce(proyectos, %{}, fn p, acc ->
        key = if Map.has_key?(p, :nombre_equipo), do: p.nombre_equipo, else: Map.get(p, :id, p)
        Map.put(acc, key, p)
      end)

    guardar_proyectos(map)
  end

  # Guardado de chats
  defp guardar_chats do
    salas =
      case safe(fn -> Hackathon.Chat.ChatServer.listar_salas() end) do
        list when is_list(list) -> list
        _ -> []
      end

    write_etf(Path.join("chat", "index.etf"), salas)

    Enum.each(salas, fn sala ->
      case Hackathon.Chat.ChatServer.obtener_historial(sala) do
        {:ok, mensajes} ->
          write_file(
            Path.join(@chat_dir, "#{sala}.etf"),
            :erlang.term_to_binary(Enum.reverse(mensajes))
          )

        _ ->
          :ok
      end
    end)
  end


  # HELPERS Y WRAPPERS SEGUROS


 @doc """
  Garantiza que los directorios de almacenamiento existen.
  """
  defp ensure_dirs do
    File.mkdir_p!(@base_dir)
    File.mkdir_p!(@chat_dir)
  end

  @doc """
  Escribe un término Elixir en formato ETF dentro del directorio de almacenamiento.
  """
  defp write_etf(rel, term) do
    full = Path.join(@base_dir, rel)
    File.mkdir_p!(Path.dirname(full))
    File.write!(full, :erlang.term_to_binary(term))
  end

  @doc """
  Carga un archivo ETF desde disco y lo convierte nuevamente a un término Elixir.
  """
  defp load_etf(rel) do
    full = Path.join(@base_dir, rel)
    if File.exists?(full), do: full |> File.read!() |> :erlang.binary_to_term()
  rescue
    _ -> nil
  end

  @doc """
  Escribe un archivo binario en disco sin aplicar serialización.
  """
  defp write_file(path, bin), do: File.write!(path, bin)

  @doc """
  Lee un archivo binario desde disco y lo convierte a un término Elixir.
  """
  defp load_file(path) do
    if File.exists?(path), do: path |> File.read!() |> :erlang.binary_to_term()
  rescue
    _ -> nil
  end

  @doc """
  Envuelve una operación en un try/rescue, devolviendo {:error, :unavailable}
  en caso de excepciones.
  """
  defp safe(fun) do
    try do
      fun.()
    rescue
      _ -> {:error, :unavailable}
    end
  end

  @doc """
  Igual que safe/1, pero garantiza devolver siempre una lista.
  Se usa en operaciones que esperan múltiples resultados.
  """
  defp safe_list(fun) do
    case safe(fun) do
      list when is_list(list) -> list
      _ -> []
    end
  end

  @doc """
  Devuelve información del nodo y del cluster
  """
  def cluster_info do
    %{
      nodo: Node.self(),
      nodos_conectados: Node.list(),
      cookie: Node.get_cookie()
    }
  end

  @doc """
  Devuelve la lista de salas persistidas en disco, sin cargar mensajes.
  Útil para inspección rápida.
  """
  def listar_salas_persistidas do
    load_etf(Path.join("chat", "index.etf")) || []
  rescue
    _ -> []
  end
end
