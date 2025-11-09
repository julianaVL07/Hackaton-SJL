defmodule Hackathon.Projects.ProjectManager do
  @moduledoc """
  GenServer que administra todos los proyectos de la hackathon.
  Se encarga de crear, actualizar y almacenar los proyectos,
  incluyendo su persistencia en archivos CSV.
  """

  use GenServer
  alias Hackathon.Projects.Project
  alias Hackathon.Storage

  # API PÚBLICA

  @doc """
  Inicia el servidor encargado de gestionar los proyectos.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Crea un nuevo proyecto con su nombre de equipo, descripción y categoría.
  Guarda el proyecto en memoria y en el archivo CSV.
  """
  def crear_proyecto(nombre_equipo, descripcion, categoria) do
    GenServer.call(__MODULE__, {:crear_proyecto, nombre_equipo, descripcion, categoria})
  end

  @doc """
  Actualiza el estado de un proyecto existente.
  Por ejemplo: `:en_progreso`, `:finalizado`, etc.
  """
  def actualizar_estado_proyecto(nombre_equipo, estado) do
    GenServer.call(__MODULE__, {:actualizar_estado, nombre_equipo, estado})
  end

  @doc """
  Agrega un nuevo avance o progreso al proyecto.
  """
  def agregar_avance_proyecto(nombre_equipo, avance) do
    GenServer.call(__MODULE__, {:agregar_avance, nombre_equipo, avance})
  end

  @doc """
  Agrega una retroalimentación de un mentor al proyecto.
  La retroalimentación incluye el nombre del mentor, el contenido del comentario y la fecha.
  """
  def agregar_retroalimentacion_proyecto(nombre_equipo, mentor_nombre, contenido) do
    GenServer.call(
      __MODULE__,
      {:agregar_retroalimentacion, nombre_equipo, mentor_nombre, contenido}
    )
  end

  @doc """
  Obtiene la información completa de un proyecto según su nombre de equipo.
  """
  def obtener_proyecto(nombre_equipo) do
    GenServer.call(__MODULE__, {:obtener_proyecto, nombre_equipo})
  end

  @doc """
  Lista todos los proyectos pertenecientes a una categoría específica.
  """
  def listar_proyectos_por_categoria(categoria) do
    GenServer.call(__MODULE__, {:listar_por_categoria, categoria})
  end

  @doc """
  Lista todos los proyectos que se encuentran en un determinado estado.
  """
  def listar_proyectos_por_estado(estado) do
    GenServer.call(__MODULE__, {:listar_por_estado, estado})
  end

  # CALLBACKS DEL SERVIDOR

  @impl true
  @doc """
  Inicializa el servidor cargando los proyectos desde el archivo CSV.
  Si no existe, empieza con un estado vacío.
  """
  def init(_initial_state) do
    state =
      case Storage.cargar_proyectos() do
        {:ok, data} -> data
        {:error, :not_found} -> %{}
      end

    {:ok, state}
  end

  @impl true
  @doc """
  Maneja la creación de un nuevo proyecto.

  Si el nombre del equipo ya existe, devuelve un error.
  En caso contrario, crea el proyecto, lo guarda y actualiza el estado del servidor.
  """
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
  @doc """
  Actualiza el estado de un proyecto existente.

  Devuelve el proyecto actualizado si se encuentra, o un error si no existe.
  """
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
  @doc """
  Agrega un avance a un proyecto.

  Si el proyecto existe, se actualiza con el nuevo avance y se guarda.
  En caso contrario, devuelve un error.
  """
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
  @doc """
  Agrega una retroalimentación de un mentor a un proyecto.

  Incluye el nombre del mentor y el contenido del comentario.
  Si el proyecto no existe, devuelve un error.
  """
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
  @doc """
  Obtiene la información completa de un proyecto por su nombre de equipo.

  Devuelve el proyecto si existe o un error si no se encuentra.
  """
  def handle_call({:obtener_proyecto, nombre_equipo}, _from, state) do
    case Map.fetch(state, nombre_equipo) do
      {:ok, proyecto} ->
        {:reply, {:ok, proyecto}, state}

      :error ->
        {:reply, {:error, :proyecto_no_encontrado}, state}
    end
  end

  @impl true
  @doc """
  Lista todos los proyectos que pertenecen a una categoría específica.
  """
  def handle_call({:listar_por_categoria, categoria}, _from, state) do
    proyectos =
      state
      |> Map.values()
      |> Enum.filter(fn proyecto -> proyecto.categoria == categoria end)

    {:reply, proyectos, state}
  end

  @impl true
  @doc """
  Lista todos los proyectos que tienen un estado determinado.
  """
  def handle_call({:listar_por_estado, estado}, _from, state) do
    proyectos =
      state
      |> Map.values()
      |> Enum.filter(fn proyecto -> proyecto.estado == estado end)

    {:reply, proyectos, state}
  end

end
