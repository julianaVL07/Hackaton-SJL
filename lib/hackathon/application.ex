defmodule Hackathon.Application do
  @moduledoc """
  Módulo principal de la aplicación Hackathon.

  Se encarga de:
    - Configurar el nodo distribuido (si aplica).
    - Iniciar los procesos supervisados:
      - Autenticación
      - Gestión de equipos y proyectos
      - Gestión de mentores
      - Servidor de chat (condicional, global en el cluster)
    - Integración con PubSub de Phoenix para comunicación en tiempo real.
  """

  use Application

  # -----------------------------
  # START
  # -----------------------------
  @impl true
  @doc """
  Punto de entrada de la aplicación.

  1. Configura el nodo distribuido si se está ejecutando en modo cluster.
  2. Determina si este nodo debe iniciar el `ChatServer`.
  3. Construye la lista de hijos a supervisar.
  4. Inicia el supervisor principal con estrategia `:one_for_one`.
  """
  def start(_type, _args) do
    configurar_nodo_distribuido()

    chat_child =
      if iniciar_chat_server?() do
        IO.puts("Este nodo iniciará el ChatServer global")
        [Hackathon.Chat.ChatServer]
      else
        IO.puts("Este nodo usará el ChatServer remoto")
        []
      end

    children =
      [
        {Phoenix.PubSub, name: Hackathon.PubSub},
        Hackathon.Auth,
        Hackathon.Teams.TeamManager,
        Hackathon.Projects.ProjectManager,
        chat_child,
        Hackathon.Mentors.MentorManager
      ]
      |> List.flatten()  # Aplana la lista por si chat_child es []

    opts = [strategy: :one_for_one, name: Hackathon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # -----------------------------
  # CONFIGURACIÓN NODO DISTRIBUIDO
  # -----------------------------
  @doc """
  Configura el nodo en modo distribuido.

  - Si se ejecuta local (`:nonode@nohost`), no hace nada.
  - Si es nodo distribuido:
      - Lee cookie de entorno `ERLANG_COOKIE` o usa valor por defecto.
      - Configura cookie del nodo.
      - Muestra información en consola.
  """
  defp configurar_nodo_distribuido do
    case Node.self() do
      :nonode@nohost ->
        IO.puts("Ejecutando en modo local (no distribuido)")
        :ok

      _ ->
        cookie = System.get_env("ERLANG_COOKIE") || "hackathon_secret_2024"
        :erlang.set_cookie(Node.self(), String.to_atom(cookie))

        IO.puts("\n===== NODO DISTRIBUIDO INICIADO =====")
        IO.puts("   Nodo: #{Node.self()}")
        IO.puts("   Cookie: #{cookie}")
        IO.puts("=============================\n")
    end
  end

  # -----------------------------
  # DECISIÓN INICIO CHAT SERVER
  # -----------------------------
  @doc """
  Determina si este nodo debe iniciar el `ChatServer` global.

  - Retorna `true` si no hay otro `ChatServer` registrado en el cluster.
  - Retorna `false` si ya existe un `ChatServer` global en otro nodo.
  """
  defp iniciar_chat_server? do
    case :global.whereis_name(Hackathon.Chat.ChatServer) do
      :undefined -> true
      _pid -> false
    end
  end
end
