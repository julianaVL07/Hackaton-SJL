defmodule Hackathon.Cluster do
  @moduledoc """
  Utilidades para gestionar el cluster distribuido.

  ## Ejemplo de uso

      # PC 1: Verificar estado
      iex> Hackathon.Cluster.info()

      # PC 2: Conectar a PC 1
      iex> Hackathon.Cluster.conectar("hackathon@192.168.1.10")

      # Enviar mensajes desde cualquier PC
      iex> Hackathon.Chat.ChatServer.enviar_mensaje("general", "Bob", "Hola!")
  """

  @doc """
  Conecta a un nodo remoto usando un string.
  """
  def conectar(nodo_remoto) when is_binary(nodo_remoto) do
    conectar(String.to_atom(nodo_remoto))
  end

  @doc """
  Conecta a un nodo remoto usando un átomo.
   """
  def conectar(nodo_remoto) when is_atom(nodo_remoto) do
    IO.puts("\n Conectando a: #{nodo_remoto}...")

    case Node.connect(nodo_remoto) do
      true ->
        IO.puts(" Conectado exitosamente")
        IO.puts("   Cluster: #{inspect([Node.self() | Node.list()])}")
        {:ok, nodo_remoto}

      false ->
        IO.puts(" Error de conexión")
        IO.puts("\n Verifica:")
        IO.puts("   1. Nodo remoto activo")
        IO.puts("   2. Mismo cookie: #{:erlang.get_cookie()}")
        IO.puts("   3. IP correcta")
        IO.puts("   4. Puerto 4369 abierto")
        {:error, :conexion_fallida}

      :ignored ->
        IO.puts("  Ya está conectado")
        {:ok, :ya_conectado}
    end
  end

  @doc """
  Muestra información del cluster y nodos conectados.
  """
  def info do
    nodos = Node.list()

    info = %{
      nodo_actual: Node.self(),
      cookie: :erlang.get_cookie(),
      nodos_conectados: nodos,
      total_nodos: length(nodos) + 1,
      chat_server_pid: :global.whereis_name(Hackathon.Chat.ChatServer)
    }

    IO.puts("\n INFORMACIÓN DEL CLUSTER")
    IO.puts("   Nodo: #{info.nodo_actual}")
    IO.puts("   Cookie: #{info.cookie}")
    IO.puts("   Nodos totales: #{info.total_nodos}")

    if Enum.empty?(nodos) do
      IO.puts("   Estado: Solo (sin otros nodos)")
    else
      IO.puts("   Nodos conectados:")
      Enum.each(nodos, fn n -> IO.puts("     • #{n}") end)
    end

    IO.puts("   ChatServer PID: #{inspect(info.chat_server_pid)}\n")

    info
  end

  @doc """
  Lista el nodo actual junto con todos los nodos conectados.
  """
  def listar_nodos, do: [Node.self() | Node.list()]

  @doc """
   Desconecta un nodo remoto usando un string.
    """
  def desconectar(nodo_remoto) when is_binary(nodo_remoto) do
    desconectar(String.to_atom(nodo_remoto))
  end

  @doc """
  Desconecta un nodo remoto usando un átomo.
  """
  def desconectar(nodo_remoto) when is_atom(nodo_remoto) do
    Node.disconnect(nodo_remoto)
    IO.puts(" Desconectado de #{nodo_remoto}")
    :ok
  end

  @doc """
   Hace ping a todos los nodos del cluster.
  """
  def ping_cluster do
    nodos = Node.list()

    if Enum.empty?(nodos) do
      IO.puts("\n No hay nodos para hacer ping\n")
      []
    else
      IO.puts("\n Ping a #{length(nodos)} nodo(s)...\n")

      Enum.map(nodos, fn nodo ->
        resultado = Node.ping(nodo)
        IO.puts("#{nodo}: #{resultado}")
        {nodo, resultado}
      end)
      |> tap(fn _ -> IO.puts("") end)
    end
  end

  @doc """
   Muestra ayuda con los comandos disponibles del cluster.
   """
  def help do
    IO.puts("""

     COMANDOS DE CLUSTER

    Hackathon.Cluster.info()
      Ver estado del cluster

    Hackathon.Cluster.conectar("hackathon@192.168.1.20")
      Conectar a otro nodo

    Hackathon.Cluster.ping_cluster()
      Verificar conectividad

    Hackathon.Cluster.listar_nodos()
      Lista todos los nodos

     Para iniciar con nombre específico:
       iex --name hackathon@192.168.1.10 --cookie mi_secreto -S mix

    """)
  end
end
