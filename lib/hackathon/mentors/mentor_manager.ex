defmodule Hackathon.Mentors.MentorManager do
  @moduledoc """
  Este módulo administra el sistema de mentoría en el hackathon.
  Sus responsabilidades incluyen:

  - Registrar mentores con su especialidad.
  - Guardar y cargar la información de mentores desde un sistema de persistencia (CSV u otro).
  - Registrar retroalimentaciones que un mentor entrega a un equipo.
  - Consultar y filtrar mentores por atributos (e.g. especialidad).

  El estado interno del GenServer es un **mapa**, donde las llaves son `mentor.id`
  y los valores son estructuras `%Mentor{}`.
  """

  use GenServer
  alias Hackathon.Mentors.Mentor
  alias Hackathon.Storage
  alias Hackathon.Projects.ProjectManager

  @storage_key "mentores"


  @doc """
  Inicia el servidor de mentores.
  Normalmente llamado desde el `Supervisor` de la aplicación.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Registra un nuevo mentor con `nombre` y `especialidad`.
  """
  def registrar_mentor(nombre, especialidad) do
    GenServer.call(__MODULE__, {:registrar_mentor, nombre, especialidad})
  end

  @doc """
  Envía retroalimentación desde un mentor (`mentor_id`) a un equipo.
  Además de registrarse dentro del mentor, también se agrega al proyecto correspondiente.
  """
  def enviar_retroalimentacion(mentor_id, equipo, contenido) do
    GenServer.call(__MODULE__, {:enviar_retroalimentacion, mentor_id, equipo, contenido})
  end

  @doc """
  Retorna la lista de todos los mentores registrados como lista de `%Mentor{}`.
  """
  def listar_mentores do
    GenServer.call(__MODULE__, :listar_mentores)
  end

  @doc """
  Obtiene un mentor por su `mentor_id`.
  """
  def obtener_mentor(mentor_id) do
    GenServer.call(__MODULE__, {:obtener_mentor, mentor_id})
  end

  @doc """
  Busca mentores que coincidan con la especialidad dada (ignorando mayúsculas/minúsculas).
  Retorna una lista de `%Mentor{}`.
  """
  def buscar_por_especialidad(especialidad) do
    GenServer.call(__MODULE__, {:buscar_por_especialidad, especialidad})
  end

  # ==============
  # CALLBACKS
  # ==============

    @impl true
    @spec init(any()) :: {:ok, map()}
    def init(_initial_state) do
      # Carga el estado desde persistencia; si no existe, usa un mapa vacío.
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
          mentor_actualizado = Mentor.agregar_retroalimentacion(mentor, equipo, contenido)
          nuevo_state = Map.put(state, mentor_id, mentor_actualizado)

          Storage.guardar_mentores(nuevo_state)

          # Registra también en el proyecto del equipo
          ProjectManager.agregar_retroalimentacion_proyecto(equipo, mentor.nombre, contenido)

          {:reply, {:ok, mentor_actualizado}, nuevo_state}

        :error ->
          {:reply, {:error, :mentor_no_encontrado}, state}
      end
    end

    @impl true
    def handle_call(:listar_mentores, _from, state) do
      {:reply, Map.values(state), state}
    end

    @impl true
    def handle_call({:obtener_mentor, mentor_id}, _from, state) do
      case Map.fetch(state, mentor_id) do
        {:ok, mentor} -> {:reply, {:ok, mentor}, state}
        :error -> {:reply, {:error, :mentor_no_encontrado}, state}
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


end
