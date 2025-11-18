defmodule Hackathon do
  @moduledoc """
  Módulo principal - API unificada para toda la aplicación.
  Exposición de todas las operaciones para equipos, proyectos, chat y mentoría.
  """

  # ============================
  #  EQUIPOS
  # ============================

  @doc "Crea un nuevo equipo con nombre y tema."
  defdelegate crear_equipo(nombre, tema), to: Hackathon.Teams.TeamManager

  @doc "Agrega un participante a un equipo existente."
  defdelegate agregar_participante(nombre_equipo, nombre_participante, email),
    to: Hackathon.Teams.TeamManager

  @doc "Lista todos los equipos registrados."
  defdelegate listar_equipos(), to: Hackathon.Teams.TeamManager

  @doc "Obtiene los datos de un equipo por nombre."
  defdelegate obtener_equipo(nombre_equipo), to: Hackathon.Teams.TeamManager

  # ============================
  #  PROYECTOS
  # ============================

  @doc "Crea un proyecto asociado a un equipo."
  defdelegate crear_proyecto(nombre_equipo, descripcion, categoria),
    to: Hackathon.Projects.ProjectManager

  @doc "Actualiza el estado de un proyecto (ej: :iniciado, :en_progreso)."
  defdelegate actualizar_estado_proyecto(nombre_equipo, estado),
    to: Hackathon.Projects.ProjectManager

  @doc "Agrega un avance textual al proyecto del equipo."
  defdelegate agregar_avance_proyecto(nombre_equipo, avance),
    to: Hackathon.Projects.ProjectManager

  @doc "Agrega retroalimentación de un mentor a un proyecto."
  defdelegate agregar_retroalimentacion_proyecto(nombre_equipo, mentor_nombre, contenido),
    to: Hackathon.Projects.ProjectManager

  @doc "Obtiene el proyecto asociado a un equipo."
  defdelegate obtener_proyecto(nombre_equipo), to: Hackathon.Projects.ProjectManager

  @doc "Filtra proyectos por categoría."
  defdelegate listar_proyectos_por_categoria(categoria),
    to: Hackathon.Projects.ProjectManager

  @doc "Filtra proyectos por estado."
  defdelegate listar_proyectos_por_estado(estado),
    to: Hackathon.Projects.ProjectManager

  # ============================
  #  CHAT
  # ============================

  @doc "Envía un mensaje a una sala de chat."
  defdelegate enviar_mensaje(sala, autor, contenido), to: Hackathon.Chat.ChatServer

  @doc "Obtiene todo el historial de una sala de chat."
  defdelegate obtener_historial(sala), to: Hackathon.Chat.ChatServer

  @doc "Crea una nueva sala de chat."
  defdelegate crear_sala(nombre_sala), to: Hackathon.Chat.ChatServer

  @doc "Lista todas las salas existentes."
  defdelegate listar_salas(), to: Hackathon.Chat.ChatServer

  # ============================
  #  MENTORES
  # ============================

  @doc "Registra un mentor con nombre y especialidad."
  defdelegate registrar_mentor(nombre, especialidad), to: Hackathon.Mentors.MentorManager

  @doc "Envia retroalimentación de un mentor a un equipo."
  defdelegate enviar_retroalimentacion(mentor_id, equipo, contenido),
    to: Hackathon.Mentors.MentorManager

  @doc "Lista todos los mentores registrados."
  defdelegate listar_mentores(), to: Hackathon.Mentors.MentorManager

  @doc "Obtiene un mentor por su ID."
  defdelegate obtener_mentor(mentor_id), to: Hackathon.Mentors.MentorManager

  # ============================
  #  RESET DEL SISTEMA
  # ============================

  @doc """
  Obtiene los datos de un mentor según su ID.
  """
  def reset do
    # Limpia archivos o datos persistidos
    Hackathon.Storage.clear_all()

    # Limpia módulos gestionados
    _ = safe_call_reset(Hackathon.Teams.TeamManager)
    _ = safe_call_reset(Hackathon.Projects.ProjectManager)
    _ = safe_call_reset(Hackathon.Mentors.MentorManager)

    # Limpia chat
    _ = safe_call_reset_chat()

    :ok
  end

  # ============================
  #  HELPERS PRIVADOS
  # ============================

  # Llama al reset/0 de un manager si existe
  defp safe_call_reset(module) do
    try do
      if function_exported?(module, :reset, 0) do
        apply(module, :reset, [])
      else
        :no_reset
      end
    rescue
      _ -> :error
    end
  end

  # Reset específico para ChatServer
  defp safe_call_reset_chat do
    try do
      if function_exported?(Hackathon.Chat.ChatServer, :reset, 0) do
        Hackathon.Chat.ChatServer.reset()
      else
        :no_reset
      end
    rescue
      _ -> :error
    end
  end
end
