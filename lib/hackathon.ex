defmodule Hackathon do
  @moduledoc """
  Módulo principal - API unificada para toda la aplicación.
  Exposición de todas las operaciones para equipos, proyectos, chat y mentoría.
  """

  # Teams
  @doc """
  Crea un equipo con un nombre y un tema.
  """
  defdelegate crear_equipo(nombre, tema), to: Hackathon.Teams.TeamManager

  @doc """
  Agrega un participante a un equipo existente, asegurando un email único.
  """
  defdelegate agregar_participante(nombre_equipo, nombre_participante, email),
    to: Hackathon.Teams.TeamManager

  @doc """
  Retorna la lista completa de equipos registrados.
  """
  defdelegate listar_equipos(), to: Hackathon.Teams.TeamManager

  @doc """
  Obtiene un equipo mediante su nombre.
  """
  defdelegate obtener_equipo(nombre_equipo), to: Hackathon.Teams.TeamManager

  # Projects
  @doc """
  Crea un nuevo proyecto asociado a un equipo, con su descripción y categoría.
  """
  defdelegate crear_proyecto(nombre_equipo, descripcion, categoria),
    to: Hackathon.Projects.ProjectManager

  @doc """
  Actualiza el estado del proyecto del equipo (ej. :iniciado, :en_progreso, :finalizado).
  """
  defdelegate actualizar_estado_proyecto(nombre_equipo, estado),
    to: Hackathon.Projects.ProjectManager

  @doc """
  Registra un avance dentro del proyecto.
  """
  defdelegate agregar_avance_proyecto(nombre_equipo, avance),
    to: Hackathon.Projects.ProjectManager

  @doc """
  Registra retroalimentación hacia el proyecto del equipo, escrita por un mentor.
  """
  @spec agregar_retroalimentacion_proyecto(any(), any(), any()) :: any()
  defdelegate agregar_retroalimentacion_proyecto(nombre_equipo, mentor_nombre, contenido),
    to: Hackathon.Projects.ProjectManager

  @doc """
  Obtiene la información del proyecto de un equipo.
  """
  defdelegate obtener_proyecto(nombre_equipo), to: Hackathon.Projects.ProjectManager

  @doc """
  Lista los proyectos filtrados por categoría.
  """
  defdelegate listar_proyectos_por_categoria(categoria), to: Hackathon.Projects.ProjectManager

  @doc """
  Lista los proyectos filtrados por estado.
  """
  defdelegate listar_proyectos_por_estado(estado), to: Hackathon.Projects.ProjectManager

  # Chat
  @doc """
  Envía un mensaje a una sala de chat existente.
  """
  defdelegate enviar_mensaje(sala, autor, contenido), to: Hackathon.Chat.ChatServer

  @doc """
  Obtiene el historial completo de mensajes de una sala.
  """
  defdelegate obtener_historial(sala), to: Hackathon.Chat.ChatServer

  @doc """
  Crea una nueva sala de chat.
  """
  defdelegate crear_sala(nombre_sala), to: Hackathon.Chat.ChatServer

  @doc """
  Lista todas las salas registradas en el sistema.
  """
  defdelegate listar_salas(), to: Hackathon.Chat.ChatServer
end
