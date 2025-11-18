defmodule Hackathon.Storage do
  @moduledoc """
  Módulo de persistencia global usando archivos ETF.
  Maneja almacenamiento de:
    - equipos
    - proyectos
    - mentores
    - chats

  Directorio base: `priv/storage`.
  Los managers llaman a `cargar_*` durante su arranque.
  `persist_state/0` guarda un snapshot completo del runtime.
  """

  @base_dir Path.join(Application.app_dir(:hackathon, "priv"), "storage")
  @chat_dir Path.join(@base_dir, "chat")

  # -----------------------------
  # BOOTSTRAP
  # -----------------------------

  @doc """
  Prepara directorios y carga todos los archivos persistidos.
  Usado al arrancar la aplicación.
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
  Guarda un *snapshot* completo del estado actual:
    - equipos
    - mentores
    - proyectos
    - chats

  Los managers proporcionan sus listas usando llamadas seguras.
  """
  def persist_state do
    ensure_dirs()

    equipos_map =
      safe_list(fn -> Hackathon.Teams.TeamManager.listar_equipos() end)
      |> Enum.reduce(%{}, &Map.put(&2, &1.nombre, &1))

    mentores_map =
      safe_list(fn -> Hackathon.Mentors.MentorManager.listar_mentores() end)
      |> Enum.reduce(%{}, fn m, acc ->
        key = Map.get(m, :id, m.nombre)
        Map.put(acc, key, m)
      end)

    proyectos_map =
      case safe(fn -> Hackathon.Projects.ProjectManager.listar_proyectos() end) do
        list when is_list(list) ->
          Enum.reduce(list, %{}, fn p, acc ->
            key = Map.get(p, :nombre_equipo, Map.get(p, :id))
            Map.put(acc, key, p)
          end)

        _ ->
          %{"default" => %{id: "default", nombre_equipo: "Equipo Sin Nombre", integrantes: [], descripcion: "Proyecto sin descripción", estado: "pendiente"}}
      end

    guardar_equipos(equipos_map)
    guardar_mentores(mentores_map)
    guardar_proyectos(proyectos_map)
    guardar_chats()

    :ok
  end

  @doc """
  Devuelve estadísticas rápidas del almacenamiento persistido:
    - cantidad de equipos, proyectos, mentores
    - número de salas de chat guardadas
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
  Borra **todo** el almacenamiento persistente.
  Usado especialmente en tests o para resetear el sistema.
  """
  def clear_all do
    File.rm_rf!(@base_dir)
    ensure_dirs()
    :ok
  end

  # -----------------------------
  # CARGA DESDE DISCO
  # -----------------------------

  @doc "Carga todos los equipos almacenados en `teams.etf`."
  def cargar_equipos do
    case load_etf("teams.etf") do
      nil -> {:ok, %{}}
      %{} = map -> {:ok, map}
      list when is_list(list) ->
        {:ok, Enum.reduce(list, %{}, &Map.put(&2, &1.nombre, &1))}
      _ -> {:ok, %{}}
    end
  rescue
    _ -> {:ok, %{}}
  end

  @doc "Carga todos los mentores desde `mentors.etf`."
  def cargar_mentores do
    case load_etf("mentors.etf") do
      nil -> {:ok, %{}}
      %{} = map -> {:ok, map}

      list when is_list(list) ->
        {:ok,
         Enum.reduce(list, %{}, fn m, acc ->
           key = Map.get(m, :id, m.nombre)
           Map.put(acc, key, m)
         end)}

      _ -> {:ok, %{}}
    end
  rescue
    _ -> {:ok, %{}}
  end

  @doc "Carga todos los proyectos desde `projects.etf`."
  def cargar_proyectos do
    case load_etf("projects.etf") do
      nil -> {:ok, %{}}
      %{} = map -> {:ok, map}

      list when is_list(list) ->
        {:ok,
         Enum.reduce(list, %{}, fn p, acc ->
           key = Map.get(p, :nombre_equipo, Map.get(p, :id))
           Map.put(acc, key, p)
         end)}

      _ -> {:ok, %{}}
    end
  rescue
    _ -> {:ok, %{}}
  end

  @doc false
  # Carga todas las salas de chat y reinyecta mensajes en los ChatServer.
  defp cargar_chats do
    salas = load_etf(Path.join("chat", "index.etf")) || []

    Enum.each(salas, fn sala ->
      mensajes = load_file(Path.join(@chat_dir, "#{sala}.etf")) || []

      safe(fn -> Hackathon.Chat.ChatServer.crear_sala(sala) end)

      Enum.reverse(mensajes)
      |> Enum.each(fn m ->
        safe(fn -> Hackathon.Chat.ChatServer.enviar_mensaje(sala, m.autor, m.contenido) end)
      end)
    end)

    :ok
  end

  # -----------------------------
  # GUARDADO EN DISCO
  # -----------------------------

  @doc "Guarda el mapa completo de equipos en `teams.etf`."
  def guardar_equipos(equipos) when is_map(equipos) do
    write_etf("teams.etf", equipos)
    :ok
  end

  @doc "Guarda equipos dada una lista convirtiéndola a mapa."
  def guardar_equipos(equipos) when is_list(equipos) do
    map = Enum.reduce(equipos, %{}, &Map.put(&2, &1.nombre, &1))
    guardar_equipos(map)
  end

  @doc "Guarda el mapa de mentores en `mentors.etf`."
  def guardar_mentores(mentores) when is_map(mentores) do
    write_etf("mentors.etf", mentores)
    :ok
  end

  @doc "Guarda mentores desde una lista convirtiendo por id o nombre."
  def guardar_mentores(mentores) when is_list(mentores) do
    map =
      Enum.reduce(mentores, %{}, fn m, acc ->
        key = Map.get(m, :id, m.nombre)
        Map.put(acc, key, m)
      end)

    guardar_mentores(map)
  end

  @doc "Guarda proyectos en `projects.etf`."
  def guardar_proyectos(proyectos) when is_map(proyectos) do
    write_etf("projects.etf", proyectos)
    :ok
  end

  @doc "Guarda proyectos desde lista convirtiéndolos a mapa."
  def guardar_proyectos(proyectos) when is_list(proyectos) do
    map =
      Enum.reduce(proyectos, %{}, fn p, acc ->
        key = Map.get(p, :nombre_equipo, Map.get(p, :id))
        Map.put(acc, key, p)
      end)

    guardar_proyectos(map)
  end

  @doc false
  # Guarda lista de salas y mensajes newest-first.
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
          write_file(Path.join(@chat_dir, "#{sala}.etf"),
                     :erlang.term_to_binary(Enum.reverse(mensajes)))

        _ -> :ok
      end
    end)
  end

  # -----------------------------
  # HELPERS DE ARCHIVOS / DIR
  # -----------------------------

  @doc false
  defp ensure_dirs do
    File.mkdir_p!(@base_dir)
    File.mkdir_p!(@chat_dir)
  end

  @doc false
  defp write_etf(rel, term) do
    full = Path.join(@base_dir, rel)
    File.mkdir_p!(Path.dirname(full))
    File.write!(full, :erlang.term_to_binary(term))
  end

  @doc false
  defp load_etf(rel) do
    full = Path.join(@base_dir, rel)
    if File.exists?(full), do: full |> File.read!() |> :erlang.binary_to_term()
  rescue
    _ -> nil
  end

  @doc false
  defp write_file(path, bin), do: File.write!(path, bin)

  @doc false
  defp load_file(path) do
    if File.exists?(path), do: path |> File.read!() |> :erlang.binary_to_term()
  rescue
    _ -> nil
  end

  # -----------------------------
  # HELPERS SAFE
  # -----------------------------

  @doc """
  Ejecuta una función atrapando cualquier excepción.
  Devuelve el resultado o `{:error, :unavailable}`.
  """
  defp safe(fun) do
    try do
      fun.()
    rescue
      _ -> {:error, :unavailable}
    end
  end

  @doc """
  Igual que `safe/1`, pero garantiza devolver una lista.
  """
  defp safe_list(fun) do
    case safe(fun) do
      list when is_list(list) -> list
      _ -> []
    end
  end

  # -----------------------------
  # INFO
  # -----------------------------

  @doc """
  Información del nodo actual:
    - nombre del nodo
    - nodos conectados
    - cookie
  """
  def cluster_info do
    %{
      nodo: Node.self(),
      nodos_conectados: Node.list(),
      cookie: Node.get_cookie()
    }
  end

  @doc """
  Lista todas las salas de chat almacenadas en disco.
  """
  def listar_salas_persistidas do
    load_etf(Path.join("chat", "index.etf")) || []
  rescue
    _ -> []
  end
end
