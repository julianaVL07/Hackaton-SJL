defmodule Hackathon.Projects.ProjectManager do
  @moduledoc """
  GenServer que gestiona todos los proyectos de la hackathon.
  Persistencia vía Hackathon.Storage (archivos ETF).
  """

  use GenServer
  alias Hackathon.Projects.Project
  alias Hackathon.Storage

  # API Pública

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def crear_proyecto(nombre_equipo, descripcion, categoria) do
    GenServer.call(__MODULE__, {:crear_proyecto, nombre_equipo, descripcion, categoria})
  end

  def actualizar_estado_proyecto(nombre_equipo, estado) do
    GenServer.call(__MODULE__, {:actualizar_estado, nombre_equipo, estado})
  end

  def agregar_avance_proyecto(nombre_equipo, avance) do
    GenServer.call(__MODULE__, {:agregar_avance, nombre_equipo, avance})
  end

  def registrar_avance(nombre_equipo, avance) do
    GenServer.call(__MODULE__, {:registrar_avance, nombre_equipo, avance})
  end

  def listar_proyectos do
    GenServer.call(__MODULE__, :listar_proyectos)
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @doc """
  Agrega una retroalimentación de mentor a un proyecto.
  """
  def agregar_retroalimentacion_proyecto(nombre_equipo, mentor_nombre, contenido) do
    GenServer.call(
      __MODULE__,
      {:agregar_retroalimentacion, nombre_equipo, mentor_nombre, contenido}
    )
  end

  def obtener_proyecto(nombre_equipo) do
    GenServer.call(__MODULE__, {:obtener_proyecto, nombre_equipo})
  end

  def listar_proyectos_por_categoria(categoria) do
    GenServer.call(__MODULE__, {:listar_por_categoria, categoria})
  end

  def listar_proyectos_por_estado(estado) do
    GenServer.call(__MODULE__, {:listar_por_estado, estado})
  end

  # Callbacks

  @impl true
  def init(_initial_state) do
    # Carga el estado desde almacenamiento ETF o usa un mapa vacío
    state =
      case Storage.cargar_proyectos() do
        {:ok, data} -> data
        {:error, :not_found} -> %{}
      end

    {:ok, state}
  end

  @impl true
  def handle_call({:crear_proyecto, nombre_equipo, descripcion, categoria}, _from, state) do
    case Map.has_key?(state, nombre_equipo) do
      true ->
        {:reply, {:error, :proyecto_existente}, state}

      false ->
        proyecto = Project.new(nombre_equipo, descripcion, categoria)
        nuevo_state = Map.put(state, nombre_equipo, proyecto)
        Storage.guardar_proyectos(nuevo_state)
        {:reply, {:ok, proyecto}, nuevo_state}
    end
  end

  @impl true
  def handle_call({:actualizar_estado, nombre_equipo, estado}, _from, state) do
    case Map.fetch(state, nombre_equipo) do
      {:ok, proyecto} ->
        proyecto_actualizado = Project.actualizar_estado(proyecto, estado)
        nuevo_state = Map.put(state, nombre_equipo, proyecto_actualizado)
        Storage.guardar_proyectos(nuevo_state)
        {:reply, {:ok, proyecto_actualizado}, nuevo_state}

      :error ->
        {:reply, {:error, :proyecto_no_encontrado}, state}
    end
  end

  @impl true
  def handle_call({:agregar_avance, nombre_equipo, avance}, _from, state) do
    case Map.fetch(state, nombre_equipo) do
      {:ok, proyecto} ->
        proyecto_actualizado = Project.agregar_avance(proyecto, avance)
        nuevo_state = Map.put(state, nombre_equipo, proyecto_actualizado)
        Storage.guardar_proyectos(nuevo_state)
        {:reply, {:ok, proyecto_actualizado}, nuevo_state}

      :error ->
        {:reply, {:error, :proyecto_no_encontrado}, state}
    end
  end

  @impl true
  def handle_call({:registrar_avance, nombre_equipo, avance}, _from, state) do
    case Map.fetch(state, nombre_equipo) do
      {:ok, proyecto} ->
        proyecto_actualizado = Project.agregar_avance(proyecto, avance)
        nuevo_state = Map.put(state, nombre_equipo, proyecto_actualizado)
        Storage.guardar_proyectos(nuevo_state)
        {:reply, {:ok, proyecto_actualizado}, nuevo_state}

      :error ->
        {:reply, {:error, :proyecto_no_encontrado}, state}
    end
  end

  @impl true
  def handle_call(
        {:agregar_retroalimentacion, nombre_equipo, mentor_nombre, contenido},
        _from,
        state
      ) do
    case Map.fetch(state, nombre_equipo) do
      {:ok, proyecto} ->
        proyecto_actualizado =
          Project.agregar_retroalimentacion(proyecto, mentor_nombre, contenido)

        nuevo_state = Map.put(state, nombre_equipo, proyecto_actualizado)
        Storage.guardar_proyectos(nuevo_state)
        {:reply, {:ok, proyecto_actualizado}, nuevo_state}

      :error ->
        {:reply, {:error, :proyecto_no_encontrado}, state}
    end
  end

  @impl true
  def handle_call({:obtener_proyecto, nombre_equipo}, _from, state) do
    case Map.fetch(state, nombre_equipo) do
      {:ok, proyecto} ->
        {:reply, {:ok, proyecto}, state}

      :error ->
        {:reply, {:error, :proyecto_no_encontrado}, state}
    end
  end

  @impl true
  def handle_call({:listar_por_categoria, categoria}, _from, state) do
    proyectos =
      state
      |> Map.values()
      |> Enum.filter(fn proyecto -> proyecto.categoria == categoria end)

    {:reply, proyectos, state}
  end

  @impl true
  def handle_call({:listar_por_estado, estado}, _from, state) do
    proyectos =
      state
      |> Map.values()
      |> Enum.filter(fn proyecto -> proyecto.estado == estado end)

    {:reply, proyectos, state}
  end

  @impl true
  def handle_call(:listar_proyectos, _from, state) do
    {:reply, Map.values(state), state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    nuevo_state = %{}
    Storage.guardar_proyectos(nuevo_state)
    {:reply, :ok, nuevo_state}
  end
end
