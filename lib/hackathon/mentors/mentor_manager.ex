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


end
