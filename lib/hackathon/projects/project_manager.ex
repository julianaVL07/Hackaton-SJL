defmodule Hackathon.Projects.ProjectManager do
  @moduledoc """
  GenServer que gestiona los proyectos del hackathon y los guarda en archivos ETF.
  """

  use GenServer
  alias Hackathon.Projects.Project
  alias Hackathon.Storage

  # API Pública

  @doc """
  Inicia el servidor de proyectos y carga los datos guardados.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Crea un proyecto nuevo con nombre de equipo, descripción y categoría.
  """
  def crear_proyecto(nombre_equipo, descripcion, categoria) do
    GenServer.call(__MODULE__, {:crear_proyecto, nombre_equipo, descripcion, categoria})
  end

  @doc """
  Actualiza el estado de un proyecto existente.
  """
  def actualizar_estado_proyecto(nombre_equipo, estado) do
    GenServer.call(__MODULE__, {:actualizar_estado, nombre_equipo, estado})
  end

  @doc """
  Agrega un avance al proyecto de un equipo.
  """
  def agregar_avance_proyecto(nombre_equipo, avance) do
    GenServer.call(__MODULE__, {:agregar_avance, nombre_equipo, avance})
  end

  @doc """
  Registra un avance adicional en un proyecto.
  """
  def registrar_avance(nombre_equipo, avance) do
    GenServer.call(__MODULE__, {:registrar_avance, nombre_equipo, avance})
  end

  @doc """
  Lista todos los proyectos del sistema.
  """
  def listar_proyectos do
    GenServer.call(__MODULE__, :listar_proyectos)
  end

  @doc """
  Agrega una retroalimentación de un mentor a un proyecto.
  """
  def agregar_retroalimentacion_proyecto(nombre_equipo, mentor_nombre, contenido) do
    GenServer.call(
      __MODULE__,
      {:agregar_retroalimentacion, nombre_equipo, mentor_nombre, contenido}
    )
  end

  @doc """
  Obtiene un proyecto según el nombre del equipo.
  """
  def obtener_proyecto(nombre_equipo) do
    GenServer.call(__MODULE__, {:obtener_proyecto, nombre_equipo})
  end

  @doc """
  Lista los proyectos que pertenecen a una categoría específica.
  """
  def listar_proyectos_por_categoria(categoria) do
    GenServer.call(__MODULE__, {:listar_por_categoria, categoria})
  end

  @doc """
  Lista los proyectos que están en un estado determinado.
  """
  def listar_proyectos_por_estado(estado) do
    GenServer.call(__MODULE__, {:listar_por_estado, estado})
  end

  # Callbacks

  @doc """
  Carga los proyectos desde almacenamiento o inicia con un estado vacío.
  """
  @impl true
  def init(_initial_state) do
    state =
      case Storage.cargar_proyectos() do
        {:ok, data} -> data
        {:error, :not_found} -> %{}
      end

    {:ok, state}
  end

  @doc """
  Maneja la creación de un proyecto y lo guarda.
  """
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

  @doc """
  Maneja la actualización del estado de un proyecto.
  """
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

  @doc """
  Maneja la adición de avances a un proyecto.
  """
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

  @doc """
  Maneja el registro de un avance adicional en un proyecto.
  """
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

  @doc """
  Maneja agregar retroalimentación al proyecto de un equipo.
  """
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

  @doc """
  Devuelve un proyecto según el nombre del equipo.
  """
  @impl true
  def handle_call({:obtener_proyecto, nombre_equipo}, _from, state) do
    case Map.fetch(state, nombre_equipo) do
      {:ok, proyecto} -> {:reply, {:ok, proyecto}, state}
      :error -> {:reply, {:error, :proyecto_no_encontrado}, state}
    end
  end

  @doc """
  Filtra los proyectos por categoría.
  """
  @impl true
  def handle_call({:listar_por_categoria, categoria}, _from, state) do
    proyectos =
      state
      |> Map.values()
      |> Enum.filter(fn proyecto -> proyecto.categoria == categoria end)

    {:reply, proyectos, state}
  end

  @doc """
  Filtra los proyectos por su estado actual.
  """
  @impl true
  def handle_call({:listar_por_estado, estado}, _from, state) do
    proyectos =
      state
      |> Map.values()
      |> Enum.filter(fn proyecto -> proyecto.estado == estado end)

    {:reply, proyectos, state}
  end

  @doc """
  Devuelve todos los proyectos registrados.
  """
  @impl true
  def handle_call(:listar_proyectos, _from, state) do
    {:reply, Map.values(state), state}
  end
end

