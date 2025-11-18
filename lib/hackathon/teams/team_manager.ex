defmodule Hackathon.Teams.TeamManager do
  @moduledoc """
  GenServer que gestiona todos los equipos de la hackathon.
  Persistencia vía Hackathon.Storage (archivos ETF).
  """

  use GenServer
  alias Hackathon.Teams.Team
  alias Hackathon.Storage

  # API Pública

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def crear_equipo(nombre, tema) do
    GenServer.call(__MODULE__, {:crear_equipo, nombre, tema})
  end

  def agregar_participante(nombre_equipo, nombre_participante, email) do
    GenServer.call(__MODULE__, {:agregar_participante, nombre_equipo, nombre_participante, email})
  end

  def listar_equipos do
    GenServer.call(__MODULE__, :listar_equipos)
  end

  def obtener_equipo(nombre_equipo) do
    GenServer.call(__MODULE__, {:obtener_equipo, nombre_equipo})
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # Callbacks

  @impl true
  def init(_initial_state) do
    # Carga estado desde Storage (map) o convierte lista legada
    state =
      case Hackathon.Storage.cargar_equipos() do
        {:ok, %{} = data} ->
          data

        {:ok, list} when is_list(list) ->
          Enum.reduce(list, %{}, fn t, acc ->
            Map.put(acc, t.nombre, t)
          end)

        _ ->
          %{}
      end

    {:ok, state}
  end

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

  @impl true
  def handle_call(:listar_equipos, _from, state) do
    equipos = Map.values(state)
    {:reply, equipos, state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    # Vacía el estado en memoria y en disco
    nuevo_state = %{}
    Storage.guardar_equipos(nuevo_state)
    {:reply, :ok, nuevo_state}
  end

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
