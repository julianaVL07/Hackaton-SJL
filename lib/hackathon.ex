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
end
