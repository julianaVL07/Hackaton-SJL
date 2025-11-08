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
  
end
