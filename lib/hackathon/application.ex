defmodule Hackathon.Application do
  use Application

  @impl true
  def start(_type, _args) do
    configurar_nodo_distribuido()

    # IMPORTANTE: Solo inicia ChatServer si es el nodo principal
    # o si no hay otros nodos conectados
    chat_child = if iniciar_chat_server?() do
      IO.puts("Este nodo iniciará el ChatServer global")
      [Hackathon.Chat.ChatServer]
    else
      IO.puts("Este nodo usará el ChatServer remoto")
      []
    end

    children = [
      {Phoenix.PubSub, name: Hackathon.PubSub},
      Hackathon.Auth,
      Hackathon.Teams.TeamManager,
      Hackathon.Projects.ProjectManager,
      # ChatServer es condicional
      chat_child,
      Hackathon.Mentors.MentorManager
    ]
    # Aplana la lista (por si chat_child es [])
    |> List.flatten()

    opts = [strategy: :one_for_one, name: Hackathon.Supervisor]
    Supervisor.start_link(children, opts)
  end

 defp configurar_nodo_distribuido do
  # Solo configurar si no estamos en modo distribuido
    case Node.self() do
      :nonode@nohost ->
        # No estamos en modo distribuido, no hacer nada
        IO.puts("Ejecutando en modo local (no distribuido)")
        :ok

      _ ->
        # Ya estamos en modo distribuido, configurar cookie
        cookie = System.get_env("ERLANG_COOKIE") || "hackathon_secret_2024"
        :erlang.set_cookie(Node.self(), String.to_atom(cookie))

        IO.puts("\n===== NODO DISTRIBUIDO INICIADO =====")
        IO.puts("   Nodo: #{Node.self()}")
        IO.puts("   Cookie: #{cookie}")
        IO.puts("=============================\n")
    end
  end

  # Determina si este nodo debe iniciar el ChatServer
  defp iniciar_chat_server? do
    # Si estás solo (sin otros nodos), inicia el ChatServer
    # Si ya hay un ChatServer global en el cluster, no lo inicies
    case :global.whereis_name(Hackathon.Chat.ChatServer) do
      :undefined ->
        # No hay ChatServer global, este nodo lo iniciará
        true
      _pid ->
        # Ya existe un ChatServer global en otro nodo
        false
    end
  end
end
