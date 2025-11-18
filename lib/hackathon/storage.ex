defmodule Hackathon.Storage do
  @moduledoc """
  Persistencia global (equipos, proyectos, mentores, chats) usando archivos ETF.
  Directorio: priv/storage
  Archivos:
    teams.etf
    projects.etf
    mentors.etf
    chat/index.etf (lista de salas)
    chat/<sala>.etf (mensajes newest-first)

  Llama bootstrap() al arrancar para cargar si existen.
  Usa persist_state() para guardar.
  """

  @base_dir Path.join(Application.app_dir(:hackathon, "priv"), "storage")
  @chat_dir Path.join(@base_dir, "chat")

  ## API

  def bootstrap do
    ensure_dirs()
    # Estas llamadas ahora sólo leen disco; los managers recuperan su estado con cargar_*/0.
    cargar_equipos()
    cargar_mentores()
    cargar_proyectos()
    cargar_chats()
    :ok
  end

  def persist_state do
    ensure_dirs()
    # Snapshot del runtime como mapas
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
      case safe(fn -> apply(Hackathon.Projects.ProjectManager, :listar_proyectos, []) end) do
        list when is_list(list) ->
          Enum.reduce(list, %{}, fn p, acc ->
            key =
              if Map.has_key?(p, :nombre_equipo), do: p.nombre_equipo, else: Map.get(p, :id, p)

            Map.put(acc, key, p)
          end)

        _ ->
          %{
            # Proyectos por defecto
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
  Elimina todo el almacenamiento persistente (úsese en tests para limpiar estado).
  """
  def clear_all do
    # Remove base storage dir completely
    try do
      File.rm_rf!(@base_dir)
    rescue
      _ -> :ok
    end

    # Recreate directories vacíos
    ensure_dirs()
    :ok
  end

  ## Carga (públicas para los managers)
  def cargar_equipos do
    case load_etf("teams.etf") do
      nil ->
        {:ok, %{}}

      %{} = map ->
        {:ok, map}

      list when is_list(list) ->
        {:ok, Enum.reduce(list, %{}, fn t, acc -> Map.put(acc, t.nombre, t) end)}

      _ ->
        {:ok, %{}}
    end
  rescue
    _ -> {:ok, %{}}
  end

  def cargar_mentores do
    case load_etf("mentors.etf") do
      nil ->
        {:ok, %{}}

      %{} = map ->
        {:ok, map}

      list when is_list(list) ->
        {:ok,
         Enum.reduce(list, %{}, fn m, acc ->
           key = if Map.has_key?(m, :id), do: m.id, else: m.nombre
           Map.put(acc, key, m)
         end)}

      _ ->
        {:ok, %{}}
    end
  rescue
    _ -> {:ok, %{}}
  end

  def cargar_proyectos do
    case load_etf("projects.etf") do
      nil ->
        {:ok, %{}}

      %{} = map ->
        {:ok, map}

      list when is_list(list) ->
        {:ok,
         Enum.reduce(list, %{}, fn p, acc ->
           key = if Map.has_key?(p, :nombre_equipo), do: p.nombre_equipo, else: Map.get(p, :id, p)
           Map.put(acc, key, p)
         end)}

      _ ->
        {:ok, %{}}
    end
  rescue
    _ -> {:ok, %{}}
  end

  # Carga de chats para bootstrap interno (mantener privada)
  defp cargar_chats do
    salas = load_etf(Path.join("chat", "index.etf")) || []

    Enum.each(salas, fn sala ->
      mensajes = load_file(Path.join(@chat_dir, "#{sala}.etf")) || []
      _ = safe(fn -> Hackathon.Chat.ChatServer.crear_sala(sala) end)
      # Reinyectar sin perder orden (almacenado newest-first)
      mensajes = Enum.reverse(mensajes)

      Enum.each(mensajes, fn m ->
        _ = safe(fn -> Hackathon.Chat.ChatServer.enviar_mensaje(sala, m.autor, m.contenido) end)
      end)
    end)

    :ok
  end

  ## Guardado (públicas con aridad 1, llamadas por los managers)

  def guardar_equipos(equipos) when is_map(equipos) do
    write_etf("teams.etf", equipos)
    :ok
  end

  def guardar_equipos(equipos) when is_list(equipos) do
    # Compat: convertir lista a mapa por nombre
    map = Enum.reduce(equipos, %{}, fn t, acc -> Map.put(acc, t.nombre, t) end)
    guardar_equipos(map)
  end

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

  # Guardado de chats (interno)
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
          # Guardar newest-first
          write_file(
            Path.join(@chat_dir, "#{sala}.etf"),
            :erlang.term_to_binary(Enum.reverse(mensajes))
          )

        _ ->
          :ok
      end
    end)
  end

  ## Helpers de directorio / ETF

  defp ensure_dirs do
    File.mkdir_p!(@base_dir)
    File.mkdir_p!(@chat_dir)
  end

  defp write_etf(rel, term) do
    full = Path.join(@base_dir, rel)
    File.mkdir_p!(Path.dirname(full))
    File.write!(full, :erlang.term_to_binary(term))
  end

  defp load_etf(rel) do
    full = Path.join(@base_dir, rel)
    if File.exists?(full), do: full |> File.read!() |> :erlang.binary_to_term()
  rescue
    _ -> nil
  end

  defp write_file(path, bin), do: File.write!(path, bin)

  defp load_file(path) do
    if File.exists?(path), do: path |> File.read!() |> :erlang.binary_to_term()
  rescue
    _ -> nil
  end

  ## Safe wrappers

  defp safe(fun) do
    try do
      fun.()
    rescue
      _ -> {:error, :unavailable}
    end
  end

  defp safe_list(fun) do
    case safe(fun) do
      list when is_list(list) -> list
      _ -> []
    end
  end

  def cluster_info do
    %{
      nodo: Node.self(),
      nodos_conectados: Node.list(),
      cookie: Node.get_cookie()
    }
  end

  def listar_salas_persistidas do
    load_etf(Path.join("chat", "index.etf")) || []
  rescue
    _ -> []
  end
end
