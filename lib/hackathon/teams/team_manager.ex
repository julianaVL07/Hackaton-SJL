defmodule Hackathon.Teams.TeamManager do
  @moduledoc """
  GenServer que gestiona todos los equipos de la hackathon.
  Se encarga de crear, listar y actualizar equipos, así como de
  agregar participantes. También maneja la persistencia de datos en CSV
  mediante el módulo `Hackathon.Storage`.
  """

  # Permite usar funciones GenServer (manejo de procesos con estado).
  use GenServer

  # Acceso corto al módulo de estructura de equipos.
  alias Hackathon.Teams.Team

  # Acceso corto al módulo encargado del almacenamiento en CSV.
  alias Hackathon.Storage

  # API Pública

  #Inicia el proceso GenServer que gestionará los equipos (inicia el GenServer con un estado vacío y lo registra con el nombre del módulo)
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  # Crea un nuevo equipo con el nombre y tema indicados.
  def crear_equipo(nombre, tema) do
    GenServer.call(__MODULE__, {:crear_equipo, nombre, tema})
  end

  # Agrega un participante a un equipo existente.
  def agregar_participante(nombre_equipo, nombre_participante, email) do
    GenServer.call(__MODULE__, {:agregar_participante, nombre_equipo, nombre_participante, email})
  end

  # Devuelve la lista completa de equipos registrados.
  def listar_equipos do
    GenServer.call(__MODULE__, :listar_equipos)
  end

  # Obtiene la información de un equipo específico por su nombre.
  def obtener_equipo(nombre_equipo) do
    GenServer.call(__MODULE__, {:obtener_equipo, nombre_equipo})
  end

end
