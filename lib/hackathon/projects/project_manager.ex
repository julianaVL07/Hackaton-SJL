defmodule Hackathon.Projects.ProjectManager do
  @moduledoc """
  GenServer que gestiona todos los proyectos de la hackathon.

  Funcionalidades:
    - Crear y actualizar proyectos.
    - Agregar avances y retroalimentaciones.
    - Consultar proyectos por nombre, categoría o estado.
    - Resetear todos los proyectos (memoria y persistencia).

  Persistencia:
    - Todos los cambios se guardan mediante `Hackathon.Storage`.
  """

  use GenServer
  alias Hackathon.Projects.Project
  alias Hackathon.Storage

  # -----------------------------
  # API PÚBLICA
  # -----------------------------

  @doc """
  Inicia el GenServer del ProjectManager.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Crea un proyecto asociado a un equipo.

  Parámetros:
    - `nombre_equipo`: nombre del equipo.
    - `descripcion`: descripción del proyecto.
    - `categoria`: categoría del proyecto (:educativo, :social, :ambiental, etc.).

  Retorna:
    - `{:ok, proyecto}` si se creó correctamente.
    - `{:error, :proyecto_existente}` si ya existe un proyecto para ese equipo.
  """
  def crear_proyecto(nombre_equipo, descripcion, categoria) do
    GenServer.call(__MODULE__, {:crear_proyecto, nombre_equipo, descripcion, categoria})
  end

  @doc """
  Actualiza el estado de un proyecto.

  Parámetros:
    - `nombre_equipo`: equipo al que pertenece el proyecto.
    - `estado`: nuevo estado del proyecto (:iniciado, :en_progreso, :finalizado).

  Retorna:
    - `{:ok, proyecto_actualizado}` si se actualizó correctamente.
    - `{:error, :proyecto_no_encontrado}` si el proyecto no existe.
  """
  def actualizar_estado_proyecto(nombre_equipo, estado) do
    GenServer.call(__MODULE__, {:actualizar_estado, nombre_equipo, estado})
  end

  @doc """
  Agrega un avance al proyecto.
  """
  def agregar_avance_proyecto(nombre_equipo, avance) do
    GenServer.call(__MODULE__, {:agregar_avance, nombre_equipo, avance})
  end

  @doc """
  Alias de `agregar_avance_proyecto/2`.
  """
  def registrar_avance(nombre_equipo, avance) do
    GenServer.call(__MODULE__, {:registrar_avance, nombre_equipo, avance})
  end

  @doc """
  Lista todos los proyectos existentes.
  """
  def listar_proyectos do
    GenServer.call(__MODULE__, :listar_proyectos)
  end

  @doc """
  Resetea todos los proyectos, tanto en memoria como en almacenamiento persistente.
  """
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @doc """
  Agrega una retroalimentación de un mentor a un proyecto.

  Parámetros:
    - `nombre_equipo`: equipo propietario del proyecto.
    - `mentor_nombre`: nombre del mentor que da la retroalimentación.
    - `contenido`: texto de la retroalimentación.
  """
  def agregar_retroalimentacion_proyecto(nombre_equipo, mentor_nombre, contenido) do
    GenServer.call(__MODULE__, {:agregar_retroalimentacion, nombre_equipo, mentor_nombre, contenido})
  end

  @doc """
  Obtiene un proyecto por nombre de equipo.

  Retorna:
    - `{:ok, proyecto}` si existe.
    - `{:error, :proyecto_no_encontrado}` si no existe.
  """
  def obtener_proyecto(nombre_equipo) do
    GenServer.call(__MODULE__, {:obtener_proyecto, nombre_equipo})
  end

  @doc """
  Lista proyectos filtrando por categoría.
  """
  def listar_proyectos_por_categoria(categoria) do
    GenServer.call(__MODULE__, {:listar_por_categoria, categoria})
  end

  @doc """
  Lista proyectos filtrando por estado.
  """
  def listar_proyectos_por_estado(estado) do
    GenServer.call(__MODULE__, {:listar_por_estado, estado})
  end

  # -----------------------------
  # CALLBACKS GENSERVER
  # -----------------------------

  @impl true
  @doc false
  def init(_initial_state) do
    # Carga el estado desde almacenamiento ETF
    state =
      case Storage.cargar_proyectos() do
        {:ok, data} -> data
        {:error, :not_found} -> %{}
      end

    {:ok, state}
  end

  @impl true
  def handle_call({:crear_proyecto, nombre_equipo, descripcion, categoria}, _from, state) do
    if Map.has_key?(state, nombre_equipo) do
      {:reply, {:error, :proyecto_existente}, state}
    else
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
    # Alias de agregar_avance
    handle_call({:agregar_avance, nombre_equipo, avance}, _from, state)
  end

  @impl true
  def handle_call({:agregar_retroalimentacion, nombre_equipo, mentor_nombre, contenido}, _from, state) do
    case Map.fetch(state, nombre_equipo) do
      {:ok, proyecto} ->
        proyecto_actualizado = Project.agregar_retroalimentacion(proyecto, mentor_nombre, contenido)
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
      {:ok, proyecto} -> {:reply, {:ok, proyecto}, state}
      :error -> {:reply, {:error, :proyecto_no_encontrado}, state}
    end
  end

  @impl true
  def handle_call({:listar_por_categoria, categoria}, _from, state) do
    proyectos =
      state
      |> Map.values()
      |> Enum.filter(fn p -> p.categoria == categoria end)

    {:reply, proyectos, state}
  end

  @impl true
  def handle_call({:listar_por_estado, estado}, _from, state) do
    proyectos =
      state
      |> Map.values()
      |> Enum.filter(fn p -> p.estado == estado end)

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
