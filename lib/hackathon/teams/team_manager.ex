defmodule Hackathon.Teams.TeamManager do
  @moduledoc """
  GenServer que gestiona los equipos de la hackathon.
  """

  use GenServer
  alias Hackathon.Teams.Team
  alias Hackathon.Storage

  # API Pública

  @doc "Inicia el servidor TeamManager."
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc "Crea un nuevo equipo con nombre y tema."
  def crear_equipo(nombre, tema) do
    GenServer.call(__MODULE__, {:crear_equipo, nombre, tema})
  end

  @doc "Agrega un participante a un equipo."
  def agregar_participante(nombre_equipo, nombre_participante, email) do
    GenServer.call(__MODULE__, {:agregar_participante, nombre_equipo, nombre_participante, email})
  end

  @doc "Devuelve la lista de equipos."
  def listar_equipos do
    GenServer.call(__MODULE__, :listar_equipos)
  end

  @doc "Obtiene la información de un equipo por su nombre."
  def obtener_equipo(nombre_equipo) do
    GenServer.call(__MODULE__, {:obtener_equipo, nombre_equipo})
  end
  
  # Callbacks

  @doc "Inicializa el estado cargando equipos desde almacenamiento."
  @impl true
  def init(_initial_state) do
    state =
      case Hackathon.Storage.cargar_equipos() do
        {:ok, %{} = data} -> data
        {:ok, list} when is_list(list) ->
          Enum.reduce(list, %{}, fn t, acc -> Map.put(acc, t.nombre, t) end)
        _ -> %{}
      end

    {:ok, state}
  end

  @doc "Callback para crear un nuevo equipo."
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

  @doc "Callback para agregar un participante a un equipo."
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

  @doc "Callback para devolver todos los equipos."
  @impl true
  def handle_call(:listar_equipos, _from, state) do
    {:reply, Map.values(state), state}
  end

  @doc "Callback para obtener los datos de un equipo."
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
