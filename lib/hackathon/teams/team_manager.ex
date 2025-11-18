defmodule Hackathon.Teams.TeamManager do
  @moduledoc """
  GenServer que gestiona los equipos de la hackathon.

  Funcionalidades principales:
  - Crear equipos
  - Agregar participantes
  - Listar y obtener equipos
  - Persistencia con `Hackathon.Storage`
  - Reinicio completo del estado
  """

  use GenServer
  alias Hackathon.Teams.Team
  alias Hackathon.Storage

  # ===================== API =====================

  @doc """
  Inicia el GenServer y carga los equipos desde disco.

  Retorna `{:ok, pid}`.
  """
  def start_link(_opts),
    do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc """
  Crea un nuevo equipo con `nombre` y `tema`.

  Retorna:
    - `{:ok, equipo}` si se creó.
    - `{:error, :equipo_existente}` si ya existe.
  """
  def crear_equipo(nombre, tema),
    do: GenServer.call(__MODULE__, {:crear_equipo, nombre, tema})

  @doc """
  Agrega un participante al equipo dado.

  Retorna:
    - `{:ok, equipo_actualizado}`
    - `{:error, :participante_duplicado}`
    - `{:error, :equipo_no_encontrado}`
  """
  def agregar_participante(eq, nombre, email),
    do: GenServer.call(__MODULE__, {:agregar_participante, eq, nombre, email})

  @doc """
  Devuelve la lista de todos los equipos registrados.
  """
  def listar_equipos,
    do: GenServer.call(__MODULE__, :listar_equipos)

  @doc """
  Obtiene un equipo por su nombre.

  Retorna:
    - `{:ok, equipo}`
    - `{:error, :equipo_no_encontrado}`
  """
  def obtener_equipo(nombre),
    do: GenServer.call(__MODULE__, {:obtener_equipo, nombre})

  @doc """
  Reinicia completamente el estado en memoria y en disco.
  """
  def reset,
    do: GenServer.call(__MODULE__, :reset)

  # ===================== CALLBACKS =====================

  @impl true
  @doc """
  Inicializa el estado del GenServer cargando los equipos desde `Storage`.

  Asegura que el estado final sea siempre un mapa:
  `%{nombre_equipo => %Team{}}`.
  """
  def init(_) do
    state =
      case Storage.cargar_equipos() do
        {:ok, %{} = mapa} ->
          mapa

        # Soporte para versiones antiguas que guardaban listas
        {:ok, lista} when is_list(lista) ->
          Map.new(lista, &{&1.nombre, &1})

        _ ->
          %{}
      end

    {:ok, state}
  end

  @impl true
  @doc """
  Maneja la creación de un equipo.

  Lógica:
    - Si el nombre existe → error.
    - Si no, crea el Team, actualiza el estado y guarda en disco.
  """
  def handle_call({:crear_equipo, nombre, tema}, _from, state) do
    if Map.has_key?(state, nombre) do
      {:reply, {:error, :equipo_existente}, state}
    else
      equipo = Team.new(nombre, tema)
      nuevo = Map.put(state, nombre, equipo)
      Storage.guardar_equipos(nuevo)
      {:reply, {:ok, equipo}, nuevo}
    end
  end

  @impl true
  @doc """
  Maneja la adición de un participante.

  Lógica:
    - Verifica que el equipo exista.
    - Delegado a `Team.agregar_participante/3`.
    - Si se actualiza, persiste el estado.
  """
  def handle_call({:agregar_participante, eq, nombre, email}, _from, state) do
    case Map.fetch(state, eq) do
      {:ok, equipo} ->
        case Team.agregar_participante(equipo, nombre, email) do
          {:ok, actualizado} ->
            nuevo = Map.put(state, eq, actualizado)
            Storage.guardar_equipos(nuevo)
            {:reply, {:ok, actualizado}, nuevo}

          {:error, razon} ->
            {:reply, {:error, razon}, state}
        end

      :error ->
        {:reply, {:error, :equipo_no_encontrado}, state}
    end
  end

  @impl true
  @doc """
  Devuelve todos los equipos existentes.

  Respuesta:
    - `{:reply, lista_de_equipos, state}`
  """
  def handle_call(:listar_equipos, _from, state),
    do: {:reply, Map.values(state), state}

  @impl true
  @doc """
  Reinicia el estado en memoria y en disco.

  Siempre retorna `:ok`.
  """
  def handle_call(:reset, _from, _state) do
    nuevo = %{}
    Storage.guardar_equipos(nuevo)
    {:reply, :ok, nuevo}
  end

  @impl true
  @doc """
  Obtiene un equipo por su nombre.

  Si existe:
    - `{:ok, equipo}`
  Si no:
    - `{:error, :equipo_no_encontrado}`
  """
  def handle_call({:obtener_equipo, nombre}, _from, state) do
    case Map.fetch(state, nombre) do
      {:ok, equipo} -> {:reply, {:ok, equipo}, state}
      :error -> {:reply, {:error, :equipo_no_encontrado}, state}
    end
  end
end
