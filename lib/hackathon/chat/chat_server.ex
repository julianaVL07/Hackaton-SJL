defmodule Hackathon.Chat.ChatServer do
  @moduledoc """
  GenServer que gestiona el chat de la hackathon con PubSub y nodos distribuidos.

  Funcionalidades:
    - Crear salas de chat.
    - Enviar mensajes.
    - Obtener historial de mensajes.
    - Listar salas.
    - Suscribirse/desuscribirse a salas.
    - Reiniciar el chat.
    - Información del cluster de nodos.
  """

  use GenServer
  alias Hackathon.Chat.Message

  @type state :: %{String.t() => [Message.t()]}

  ## API PÚBLICA

  @doc """
  Inicia el ChatServer con registro global.
  Si ya existe otro servidor, ignora el inicio y usa el remoto.
  """
  def start_link(_opts) do
    case GenServer.start_link(__MODULE__, %{"general" => []}, name: {:global, __MODULE__}) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} ->
        IO.puts("Usando ChatServer remoto en nodo #{node(pid)}")
        :ignore
    end
  end

  @doc "Crea una nueva sala de chat con el nombre indicado."
  def crear_sala(nombre_sala), do: safe_call({:crear_sala, nombre_sala})

  @doc "Envía un mensaje a la sala especificada."
  def enviar_mensaje(sala, autor, contenido), do: safe_cast({:enviar_mensaje, sala, autor, contenido})

  @doc "Obtiene el historial de mensajes de la sala indicada (más antiguos primero)."
  def obtener_historial(sala), do: safe_call({:obtener_historial, sala})

  @doc "Lista todas las salas existentes."
  def listar_salas, do: safe_call(:listar_salas)

  @doc "Reinicia el chat, dejando solo la sala 'general'."
  def reset, do: safe_call(:reset)

  @doc "Se suscribe a los mensajes de la sala usando PubSub."
  def suscribirse(sala), do: Phoenix.PubSub.subscribe(Hackathon.PubSub, "chat:#{sala}")

  @doc "Se desuscribe de los mensajes de la sala usando PubSub."
  def desuscribirse(sala), do: Phoenix.PubSub.unsubscribe(Hackathon.PubSub, "chat:#{sala}")

  @doc "Devuelve información del cluster y del servidor de chat principal."
  def info_cluster do
    %{
      nodo_actual: Node.self(),
      nodos_conectados: Node.list(),
      total_nodos: length(Node.list()) + 1,
      servidor_principal: :global.whereis_name(__MODULE__)
    }
  end

  ## HELPERS PRIVADOS

  @doc "Llama de forma segura a GenServer.call, manejando ChatServer remoto no disponible"
  defp safe_call(mensaje, timeout \\ 5000) do
    case :global.whereis_name(__MODULE__) do
      :undefined -> {:error, :chat_server_no_disponible}
      pid -> GenServer.call(pid, mensaje, timeout)
    end
  rescue
    e -> {:error, {:exception, e}}
  end

  @doc "Llama de forma segura a GenServer.cast, manejando ChatServer remoto no disponible"
  defp safe_cast(mensaje) do
    case :global.whereis_name(__MODULE__) do
      :undefined -> {:error, :chat_server_no_disponible}
      pid -> GenServer.cast(pid, mensaje); :ok
    end
  rescue
    e -> {:error, {:exception, e}}
  end

  ## CALLBACKS DE GENSERVER

  @doc "Inicializa el estado del ChatServer y monitorea nodos del cluster."
  @impl true
  def init(initial_state) do
    :net_kernel.monitor_nodes(true)
    IO.puts("ChatServer iniciado en nodo: #{Node.self()}")
    {:ok, initial_state}
  end

  @doc "Crea una sala si no existe."
  @impl true
  def handle_call({:crear_sala, nombre_sala}, _from, state) do
    if Map.has_key?(state, nombre_sala) do
      {:reply, {:error, :sala_existente}, state}
    else
      nuevo_state = Map.put(state, nombre_sala, [])
      IO.puts("Sala creada: #{nombre_sala} en nodo #{Node.self()}")
      {:reply, {:ok, nombre_sala}, nuevo_state}
    end
  end

  @doc "Devuelve el historial de mensajes de una sala."
  @impl true
  def handle_call({:obtener_historial, sala}, _from, state) do
    case Map.fetch(state, sala) do
      {:ok, mensajes} -> {:reply, {:ok, Enum.reverse(mensajes)}, state}
      :error -> {:reply, {:error, :sala_no_encontrada}, state}
    end
  end

  @doc "Lista todas las salas existentes."
  @impl true
  def handle_call(:listar_salas, _from, state), do: {:reply, Map.keys(state), state}

  @doc "Reinicia el chat dejando solo la sala 'general'."
  @impl true
  def handle_call(:reset, _from, _state), do: {:reply, :ok, %{"general" => []}}

  @doc "Agrega un mensaje a la sala y lo publica vía PubSub."
  @impl true
  def handle_cast({:enviar_mensaje, sala, autor, contenido}, state) do
    if Map.has_key?(state, sala) do
      mensaje = Message.new(autor, contenido, sala)
      nuevo_state = Map.put(state, sala, [mensaje | Map.get(state, sala)])
      Phoenix.PubSub.broadcast(Hackathon.PubSub, "chat:#{sala}", {:nuevo_mensaje, mensaje})
      IO.puts("[#{Node.self()}] Mensaje: [#{sala}] #{autor}: #{contenido}")
      {:noreply, nuevo_state}
    else
      IO.puts("Sala no encontrada: #{sala}")
      {:noreply, state}
    end
  end

  @doc "Maneja la conexión de un nodo al cluster."
  @impl true
  def handle_info({:nodeup, nodo}, state) do
    IO.puts("Nodo conectado: #{nodo}")
    {:noreply, state}
  end

  @doc "Maneja la desconexión de un nodo del cluster."
  @impl true
  def handle_info({:nodedown, nodo}, state) do
    IO.puts("Nodo desconectado: #{nodo}")
    {:noreply, state}
  end

  @doc "Ignora otros mensajes genéricos."
  @impl true
  def handle_info(_msg, state), do: {:noreply, state}
end
