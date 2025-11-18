defmodule Hackathon.Mentors.MentorManager do
  @moduledoc """
  GenServer que gestiona mentores y el sistema de mentoría.
  Ahora incluye persistencia en CSV y registra retroalimentaciones en proyectos.
  """

  use GenServer
  alias Hackathon.Mentors.Mentor
  alias Hackathon.Storage
  alias Hackathon.Projects.ProjectManager

  @storage_key "mentores"

  # API Pública

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def registrar_mentor(nombre, especialidad) do
    GenServer.call(__MODULE__, {:registrar_mentor, nombre, especialidad})
  end

  def enviar_retroalimentacion(mentor_id, equipo, contenido) do
    GenServer.call(__MODULE__, {:enviar_retroalimentacion, mentor_id, equipo, contenido})
  end

  def listar_mentores do
    GenServer.call(__MODULE__, :listar_mentores)
  end

  def obtener_mentor(mentor_id) do
    GenServer.call(__MODULE__, {:obtener_mentor, mentor_id})
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  def buscar_por_especialidad(especialidad) do
    GenServer.call(__MODULE__, {:buscar_por_especialidad, especialidad})
  end

  # Callbacks

  @impl true
  def init(_initial_state) do
    # Carga el estado desde CSV o usa un mapa vacío
    state =
      case Storage.cargar_mentores() do
        {:ok, data} -> data
        {:error, :not_found} -> %{}
      end

    {:ok, state}
  end

  @impl true
  def handle_call({:registrar_mentor, nombre, especialidad}, _from, state) do
    mentor = Mentor.new(nombre, especialidad)
    nuevo_state = Map.put(state, mentor.id, mentor)
    Storage.guardar_mentores(nuevo_state)
    {:reply, {:ok, mentor}, nuevo_state}
  end

  @impl true
  def handle_call({:enviar_retroalimentacion, mentor_id, equipo, contenido}, _from, state) do
    case Map.fetch(state, mentor_id) do
      {:ok, mentor} ->
        # Actualiza el mentor con la retroalimentación
        mentor_actualizado = Mentor.agregar_retroalimentacion(mentor, equipo, contenido)
        nuevo_state = Map.put(state, mentor_id, mentor_actualizado)
        Storage.guardar_mentores(nuevo_state)

        # También registra la retroalimentación en el proyecto del equipo
        ProjectManager.agregar_retroalimentacion_proyecto(equipo, mentor.nombre, contenido)

        {:reply, {:ok, mentor_actualizado}, nuevo_state}

      :error ->
        {:reply, {:error, :mentor_no_encontrado}, state}
    end
  end

  @impl true
  def handle_call(:listar_mentores, _from, state) do
    mentores = Map.values(state)
    {:reply, mentores, state}
  end

  @impl true
  def handle_call({:obtener_mentor, mentor_id}, _from, state) do
    case Map.fetch(state, mentor_id) do
      {:ok, mentor} ->
        {:reply, {:ok, mentor}, state}

      :error ->
        {:reply, {:error, :mentor_no_encontrado}, state}
    end
  end

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

  @impl true
  def handle_call(:reset, _from, _state) do
    nuevo_state = %{}
    Storage.guardar_mentores(nuevo_state)
    {:reply, :ok, nuevo_state}
  end
end
