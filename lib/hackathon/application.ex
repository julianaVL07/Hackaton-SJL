defmodule Hackathon.Application do
  @moduledoc """
  Módulo principal de la aplicación OTP de Hackathon.
  El ChatServer se inicia solo en un nodo del cluster para evitar
  conflictos de registro global y garantizar consistencia en la mensajería.
  """

  use Application

  @impl true
  def start(_type, _args) do
    configurar_nodo_distribuido()

    # Determina dinámicamente si este nodo debe iniciar el ChatServer global.
    # Si ya existe un ChatServer registrado globalmente, el nodo no lo inicia.
    chat_child =
      if iniciar_chat_server?() do
        IO.puts("Este nodo iniciará el ChatServer global")
        [Hackathon.Chat.ChatServer]
      else
        IO.puts("Este nodo usará el ChatServer remoto")
        []
      end

    # Lista de procesos supervisados por la aplicación
    children =
      [
        {Phoenix.PubSub, name: Hackathon.PubSub},
        Hackathon.Auth,
        Hackathon.Teams.TeamManager,
        Hackathon.Projects.ProjectManager,
        chat_child,                     # Solo se agrega si debe iniciarse
        Hackathon.Mentors.MentorManager
      ]
      |> List.flatten()                 # Evita listas anidadas si chat_child = []

    # Supervisor OTP raíz
    opts = [strategy: :one_for_one, name: Hackathon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Configura el nodo para operación distribuida.
  """
  defp configurar_nodo_distribuido do
    case Node.self() do
      :nonode@nohost ->
        IO.puts("Ejecutando en modo local (no distribuido)")
        :ok

      _ ->
        # Recupera cookie del entorno, o usa la cookie por defecto
        cookie = System.get_env("ERLANG_COOKIE") || "hackathon_secret_2024"

        :erlang.set_cookie(Node.self(), String.to_atom(cookie))

        IO.puts("\n===== NODO DISTRIBUIDO INICIADO =====")
        IO.puts("   Nodo: #{Node.self()}")
        IO.puts("   Cookie: #{cookie}")
        IO.puts("=============================\n")
    end
  end

  @doc """
  Determina si este nodo debe iniciar el ChatServer.
  """
  defp iniciar_chat_server? do
    case :global.whereis_name(Hackathon.Chat.ChatServer) do
      :undefined ->
        true     # No existe ChatServer en el cluster → iniciarlo aquí

      _pid ->
        false    # ChatServer ya está corriendo en otro nodo
    end
  end
end
