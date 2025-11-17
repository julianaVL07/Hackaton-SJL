defmodule Hackathon.Mentors.MentorManager do
  @moduledoc """
  GenServer que administra mentores, su registro, búsqueda y retroalimentaciones.
  Incluye persistencia en CSV.
  """

  use GenServer
  alias Hackathon.Mentors.Mentor
  alias Hackathon.Storage
  alias Hackathon.Projects.ProjectManager

  @storage_key "mentores"

  # API Pública

  @doc """
  Inicia el servidor de mentores y carga los datos guardados.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Registra un nuevo mentor con nombre y especialidad.
  """
  def registrar_mentor(nombre, especialidad) do
    GenServer.call(__MODULE__, {:registrar_mentor, nombre, especialidad})
  end

  @doc """
  Envía retroalimentación de un mentor hacia un equipo.
  """
  def enviar_retroalimentacion(mentor_id, equipo, contenido) do
    GenServer.call(__MODULE__, {:enviar_retroalimentacion, mentor_id, equipo, contenido})
  end

  @doc """
  Devuelve la lista completa de mentores registrados.
  """
  def listar_mentores do
    GenServer.call(__MODULE__, :listar_mentores)
  end

  @doc """
  Obtiene la información de un mentor por su ID.
  """
  def obtener_mentor(mentor_id) do
    GenServer.call(__MODULE__, {:obtener_mentor, mentor_id})
  end

  @doc """
  Busca mentores por una especialidad dada.
  """
  def buscar_por_especialidad(especialidad) do
    GenServer.call(__MODULE__, {:buscar_por_especialidad, especialidad})
  end

  # Callbacks

  @doc """
  Carga los mentores desde almacenamiento o inicia un estado vacío.
  """
  @impl true
  def init(_initial_state) do
    state =
      case Storage.cargar_mentores() do
        {:ok, data} -> data
        {:error, :not_found} -> %{}
      end

    {:ok, state}
  end

  @doc """
  Maneja el registro de un mentor y actualiza el almacenamiento.
  """
  @impl true
  def handle_call({:registrar_mentor, nombre, especialidad}, _from, state) do
    mentor = Mentor.new(nombre, especialidad)
    nuevo_state = Map.put(state, mentor.id, mentor)
    Storage.guardar_mentores(nuevo_state)
    {:reply, {:ok, mentor}, nuevo_state}
  end

  @doc """
  Maneja la retroalimentación enviada por un mentor y la registra en el proyecto.
  """
  @impl true
  def handle_call({:enviar_retroalimentacion, mentor_id, equipo, contenido}, _from, state) do
    case Map.fetch(state, mentor_id) do
      {:ok, mentor} ->
        mentor_actualizado = Mentor.agregar_retroalimentacion(mentor, equipo, contenido)
        nuevo_state = Map.put(state, mentor_id, mentor_actualizado)
        Storage.guardar_mentores(nuevo_state)

        ProjectManager.agregar_retroalimentacion_proyecto(equipo, mentor.nombre, contenido)

        {:reply, {:ok, mentor_actualizado}, nuevo_state}

      :error ->
        {:reply, {:error, :mentor_no_encontrado}, state}
    end
  end

  @doc """
  Devuelve todos los mentores del sistema.
  """
  @impl true
  def handle_call(:listar_mentores, _from, state) do
    {:reply, Map.values(state), state}
  end

  @doc """
  Devuelve un mentor según su ID.
  """
  @impl true
  def handle_call({:obtener_mentor, mentor_id}, _from, state) do
    case Map.fetch(state, mentor_id) do
      {:ok, mentor} -> {:reply, {:ok, mentor}, state}
      :error -> {:reply, {:error, :mentor_no_encontrado}, state}
    end
  end

  @doc """
  Filtra mentores por una especialidad dada.
  """
  @impl true
  def handle_call({:buscar_por_especialidad, especialidad}, _from, state) do
    mentores =
      state
      |> Map.values()
      |> Enum.filter(fn mentor ->
        String.downcase(mentor.especialidad) == String.downcase(especialidad)
      end)

    {:reply, mentores, state}
  end
end

