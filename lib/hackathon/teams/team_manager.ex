defmodule Hackathon.Teams.TeamManager do
  @moduledoc """
  GenServer que gestiona todos los equipos de la hackathon.
  Se encarga de crear, listar y actualizar equipos, así como de
  agregar participantes. También maneja la persistencia de datos en CSV
  mediante el módulo `Hackathon.Storage`.
  """

  # Permite usar funciones GenServer (manejo de procesos con estado).
  use GenServer

  # Acceso corto al módulo de estructura de equipos.
  alias Hackathon.Teams.Team

  # Acceso corto al módulo encargado del almacenamiento en CSV.
  alias Hackathon.Storage

  # API Pública

  #Inicia el proceso GenServer que gestionará los equipos (inicia el GenServer con un estado vacío y lo registra con el nombre del módulo)
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Crea un nuevo equipo con el nombre y tema indicados.
  def crear_equipo(nombre, tema) do
    GenServer.call(__MODULE__, {:crear_equipo, nombre, tema})
  end

  # Agrega un participante a un equipo existente.
  def agregar_participante(nombre_equipo, nombre_participante, email) do
    GenServer.call(__MODULE__, {:agregar_participante, nombre_equipo, nombre_participante, email})
  end

  # Devuelve la lista completa de equipos registrados.
  def listar_equipos do
    GenServer.call(__MODULE__, :listar_equipos)
  end

  # Obtiene la información de un equipo específico por su nombre.
  def obtener_equipo(nombre_equipo) do
    GenServer.call(__MODULE__, {:obtener_equipo, nombre_equipo})
  end

  # Callbacks

  @doc """
  Inicializa el GenServer cargando los equipos desde almacenamiento persistente.
  Si no hay datos guardados, inicia con un mapa vacío.
  """
  @impl true
  def init(_initial_state) do
    state =
      case Storage.cargar_equipos() do
        {:ok, data} -> data
        {:error, :not_found} -> %{}
      end

    {:ok, state}
  end

  @doc """
  Crea un nuevo equipo con el `nombre` y `tema` proporcionados.

  - Si el equipo ya existe, devuelve `{:error, :equipo_existente}`.
  - Si no existe, lo crea, lo agrega al estado y persiste los cambios.
  """
  @impl true
  def handle_call({:crear_equipo, nombre, tema}, _from, state) do
    case Map.has_key?(state, nombre) do
      true ->
        {:reply, {:error, :equipo_existente}, state}

      false ->
        equipo = Team.new(nombre, tema)
        nuevo_state = Map.put(state, nombre, equipo)
        Storage.guardar_equipos(nuevo_state)
        {:reply, {:ok, equipo}, nuevo_state}
    end
  end

  @doc """
  Agrega un participante a un equipo existente.

  Recibe:
    - `nombre_equipo`: nombre del equipo al que se agregará el participante
    - `nombre_participante`: nombre del participante
    - `email`: correo electrónico del participante

  Comportamiento:
    - Si el equipo no existe, devuelve `{:error, :equipo_no_encontrado}`.
    - Si ocurre un error al agregar el participante, devuelve `{:error, reason}`.
    - Si se agrega correctamente, actualiza el estado y persiste los cambios.
  """
  @impl true
  def handle_call(
        {:agregar_participante, nombre_equipo, nombre_participante, email},
        _from,
        state
      ) do
    case Map.fetch(state, nombre_equipo) do
      {:ok, equipo} ->
        case Team.agregar_participante(equipo, nombre_participante, email) do
          {:ok, equipo_actualizado} ->
            nuevo_state = Map.put(state, nombre_equipo, equipo_actualizado)
            Storage.guardar_equipos(nuevo_state)
            {:reply, {:ok, equipo_actualizado}, nuevo_state}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end

      :error ->
        {:reply, {:error, :equipo_no_encontrado}, state}
    end
  end

  @doc """
  Devuelve la lista de todos los equipos actualmente almacenados en el estado.
  """
  @impl true
  def handle_call(:listar_equipos, _from, state) do
    equipos = Map.values(state)
    {:reply, equipos, state}
  end

  @doc """
  Devuelve un equipo específico por su nombre.

  - Si el equipo existe, retorna `{:ok, equipo}`.
  - Si no existe, retorna `{:error, :equipo_no_encontrado}`.
  """
  @impl true
  def handle_call({:obtener_equipo, nombre_equipo}, _from, state) do
    case Map.fetch(state, nombre_equipo) do
      {:ok, equipo} ->
        {:reply, {:ok, equipo}, state}

      :error ->
        {:reply, {:error, :equipo_no_encontrado}, state}
    end
  end
end
