defmodule Hackathon.Application do
  @moduledoc """
  Punto de entrada de la aplicación.
  Este módulo define el árbol de supervisión inicial que se ejecuta cuando la
  aplicación arranca. Aquí se registran y supervisan todos los procesos clave
  del sistema.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: Hackathon.PubSub},
      Hackathon.Auth,
      Hackathon.Teams.TeamManager,
      Hackathon.Projects.ProjectManager,
      Hackathon.Chat.ChatServer,
      Hackathon.Mentors.MentorManager
    ]

    opts = [strategy: :one_for_one, name: Hackathon.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
