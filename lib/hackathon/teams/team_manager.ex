defmodule Hackathon.Teams.TeamManager do
  @moduledoc """
  GenServer que gestiona todos los equipos de la hackathon.

  Funcionalidades:
    - Crear equipos y verificar duplicados.
    - Agregar participantes a equipos existentes.
    - Listar y obtener equipos por nombre.
    - Resetear todos los equipos (memoria y persistencia).

  Persistencia:
    - Todos los cambios se guardan mediante `Hackathon.Storage`.
  """

  use GenServer
  alias Hackathon.Teams.Team
  alias Hackathon.Storage

  # -----------------------------
  # API PÚBLICA
  # -----------------------------

  @doc """
  Inicia el GenServer del TeamManager.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Crea un equipo con el `nombre` y `tema` proporcionados.

  Retorna:
    - `{:ok, equipo}` si se creó correctamente.
    - `{:error, :equipo_existente}` si ya existe un equipo con ese nombre.
  """
  def crear_equipo(nombre, tema) do
    GenServer.call(__MODULE__, {:crear_equipo, nombre, tema})
  end

  @doc """
  Agrega un participante a un equipo existente.

  Parámetros:
    - `nombre_equipo`: Nombre del equipo.
    - `nombre_participante`: Nombre del participante.
    - `email`: Email único del participante.

  Retorna:
    - `{:ok, equipo_actualizado}` si se agregó correctamente.
    - `{:error, :participante_duplicado}` si el email ya existe en el equipo.
    - `{:error, :equipo_no_encontrado}` si el equipo no existe.
  """
  def agregar_participante(nombre_equipo, nombre_participante, email) do
    GenServer.call(__MODULE__, {:agregar_participante, nombre_equipo, nombre_participante, email})
  end

  @doc """
  Devuelve todos los equipos en forma de lista.
  """
  def listar_equipos do
    GenServer.call(__MODULE__, :listar_equipos)
  end

  @doc """
  Obtiene un equipo por su nombre.

  Retorna:
    - `{:ok, equipo}` si existe.
    - `{:error, :equipo_no_encontrado}` si no existe.
  """
  def obtener_equipo(nombre_equipo) do
    GenServer.call(__MODULE__, {:obtener_equipo, nombre_equipo})
  end

  @doc """
  Resetea todos los equipos, tanto en memoria como en almacenamiento persistente.
  Usado principalmente en tests.
  """
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # -----------------------------
  # CALLBACKS GENSERVER
  # -----------------------------

  @impl true
  @doc false
  def init(_initial_state) do
    # Carga el estado inicial desde Storage
    state =
      case Hackathon.Storage.cargar_equipos() do
        {:ok, %{} = data} -> data
        {:ok, list} when is_list(list) ->
          Enum.reduce(list, %{}, fn t, acc -> Map.put(acc, t.nombre, t) end)
        _ -> %{}
      end

    {:ok, state}
  end

  @impl true
  def handle_call({:crear_equipo, nombre, tema}, _from, state) do
    if Map.has_key?(state, nombre) do
      {:reply, {:error, :equipo_existente}, state}
    else
      equipo = Team.new(nombre, tema)
      nuevo_state = Map.put(state, nombre, equipo)
      Storage.guardar_equipos(nuevo_state)
      {:reply, {:ok, equipo}, nuevo_state}
    end
  end

  @impl true
  def handle_call({:agregar_participante, nombre_equipo, nombre_participante, email}, _from, state) do
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

  @impl true
  def handle_call(:listar_equipos, _from, state) do
    {:reply, Map.values(state), state}
  end

  @impl true
  def handle_call({:obtener_equipo, nombre_equipo}, _from, state) do
    case Map.fetch(state, nombre_equipo) do
      {:ok, equipo} -> {:reply, {:ok, equipo}, state}
      :error -> {:reply, {:error, :equipo_no_encontrado}, state}
    end
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    nuevo_state = %{}
    Storage.guardar_equipos(nuevo_state)
    {:reply, :ok, nuevo_state}
  end
end
