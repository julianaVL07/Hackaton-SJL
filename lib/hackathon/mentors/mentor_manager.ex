defmodule Hackathon.Mentors.MentorManager do
  @moduledoc """
  GenServer que gestiona los mentores del sistema.

  Funciones principales:
    - Registrar mentores
    - Listar y buscar por especialidad
    - Enviar retroalimentación a proyectos
    - Guardar y cargar mentores desde almacenamiento (CSV/ETF)
  """

  use GenServer
  alias Hackathon.Mentors.Mentor
  alias Hackathon.Storage
  alias Hackathon.Projects.ProjectManager

  @storage_key "mentores"

  # =============
  #   API Pública
  # =============

  @doc """
  Inicia el GenServer cargando mentores desde almacenamiento.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Registra un mentor nuevo con `nombre` y `especialidad`.

  Retorna `{:ok, mentor}`.
  """
  def registrar_mentor(nombre, especialidad) do
    GenServer.call(__MODULE__, {:registrar_mentor, nombre, especialidad})
  end

  @doc """
  Envía retroalimentación a un equipo desde un mentor.

  También guarda la retroalimentación en el proyecto.
  """
  def enviar_retroalimentacion(mentor_id, equipo, contenido) do
    GenServer.call(__MODULE__, {:enviar_retroalimentacion, mentor_id, equipo, contenido})
  end

  @doc """
  Lista todos los mentores registrados.
  """
  def listar_mentores do
    GenServer.call(__MODULE__, :listar_mentores)
  end

  @doc """
  Obtiene un mentor por ID.
  """
  def obtener_mentor(mentor_id) do
    GenServer.call(__MODULE__, {:obtener_mentor, mentor_id})
  end

  @doc """
  Limpia todos los mentores del sistema.
  """
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @doc """
  Busca mentores por especialidad (insensible a mayúsculas/minúsculas).
  """
  def buscar_por_especialidad(especialidad) do
    GenServer.call(__MODULE__, {:buscar_por_especialidad, especialidad})
  end

  # =====================
  #   CALLBACKS GenServer
  # =====================

  @impl true
  @doc """
  Carga los mentores desde almacenamiento.
  Si no existe archivo, arranca con un mapa vacío.
  """
  def init(_initial_state) do
    state =
      case Storage.cargar_mentores() do
        {:ok, data} -> data
        {:error, :not_found} -> %{}
      end

    {:ok, state}
  end

  @impl true
  @doc """
  Maneja el registro de un nuevo mentor.
  """
  def handle_call({:registrar_mentor, nombre, especialidad}, _from, state) do
    mentor = Mentor.new(nombre, especialidad)
    nuevo_state = Map.put(state, mentor.id, mentor)
    Storage.guardar_mentores(nuevo_state)

    {:reply, {:ok, mentor}, nuevo_state}
  end

  @impl true
  @doc """
  Maneja el envío de retroalimentación por un mentor.

  - Actualiza el mentor agregando la retroalimentación.
  - Registra la misma retroalimentación en el proyecto del equipo.
  """
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

  @impl true
  @doc """
  Retorna la lista completa de mentores.
  """
  def handle_call(:listar_mentores, _from, state) do
    {:reply, Map.values(state), state}
  end

  @impl true
  @doc """
  Busca y retorna un mentor por ID.
  """
  def handle_call({:obtener_mentor, mentor_id}, _from, state) do
    case Map.fetch(state, mentor_id) do
      {:ok, mentor} ->
        {:reply, {:ok, mentor}, state}

      :error ->
        {:reply, {:error, :mentor_no_encontrado}, state}
    end
  end

  @impl true
  @doc """
  Filtra mentores por especialidad exacta (case-insensitive).
  """
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
  @doc """
  Resetea el estado eliminando todos los mentores.
  """
  def handle_call(:reset, _from, _state) do
    nuevo_state = %{}
    Storage.guardar_mentores(nuevo_state)

    {:reply, :ok, nuevo_state}
  end
end
