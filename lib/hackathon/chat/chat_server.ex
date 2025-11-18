defmodule Hackathon.Chat.ChatServer do
  @moduledoc """
  GenServer que gestiona el sistema de chat usando PubSub.

  Funcionalidades principales:
  - Crear y listar salas de chat.
  - Enviar y recibir mensajes en tiempo real.
  - Guardar el historial de mensajes por sala.
  - Mantener un canal general para anuncios.
  """

  use GenServer
  alias Hackathon.Chat.Message

  @type state :: %{String.t() => [Message.t()]}

  # ========================
  #      API PÚBLICA
  # ========================

  @doc """
  Inicia el ChatServer usando registro global.

  Si ya existe en otro nodo:
    - No crea uno nuevo.
    - Se conecta al existente.
  """
  def start_link(_opts) do
    case GenServer.start_link(__MODULE__, %{"general" => []}, name: {:global, __MODULE__}) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        IO.puts("Usando ChatServer remoto en nodo #{node(pid)}")
        :ignore
    end
  end

  @doc """
  Crea una nueva sala de chat con el nombre dado.
  Retorna un error si la sala ya existe.
  """
  def crear_sala(nombre_sala) do
    safe_call({:crear_sala, nombre_sala})
  end

  @doc """
  Envía un mensaje a una sala.

  Usado para comunicación en tiempo real.
  """
  def enviar_mensaje(sala, autor, contenido) do
    safe_cast({:enviar_mensaje, sala, autor, contenido})
  end

  @doc """
  Obtiene el historial completo de una sala como lista de mensajes.
  """
  def obtener_historial(sala) do
    safe_call({:obtener_historial, sala})
  end

  @doc """
  Retorna todas las salas existentes en el sistema.
  """
  def listar_salas do
    safe_call(:listar_salas)
  end

  @doc """
  Reinicia el estado del chat, dejando solo la sala 'general'.
  """
  def reset do
    safe_call(:reset)
  end

  @doc """
  Suscribe un proceso a una sala específica.
  El proceso recibirá los mensajes nuevos que se envíen en esa sala.
  """
  def suscribirse(sala) do
    Phoenix.PubSub.subscribe(Hackathon.PubSub, "chat:#{sala}")
  end

  @doc """
  Cancela la suscripción a los eventos de una sala.
  """
  def desuscribirse(sala) do
    Phoenix.PubSub.unsubscribe(Hackathon.PubSub, "chat:#{sala}")
  end

  # CALLBACKS DEL SERVIDOR

  @impl true
  @doc """
  Configura el estado inicial e inicia el monitoreo de nodos del cluster.
  """
  def init(initial_state) do
    :net_kernel.monitor_nodes(true)

    IO.puts("ChatServer iniciado en nodo: #{Node.self()}")
    IO.puts("   PID global: #{inspect(self())}")

    {:ok, initial_state}
  end

  @impl true
  @doc """
  Crea una sala de chat si no existe.
  """
  def handle_call({:crear_sala, nombre_sala}, _from, state) do
    if Map.has_key?(state, nombre_sala) do
      {:reply, {:error, :sala_existente}, state}
    else
      nuevo_state = Map.put(state, nombre_sala, [])
      IO.puts("Sala creada: #{nombre_sala} en nodo #{Node.self()}")
      {:reply, {:ok, nombre_sala}, nuevo_state}
    end
  end

  @impl true
  @doc """
  Retorna el historial de una sala (ordenado del más antiguo al más reciente).
  """
  def handle_call({:obtener_historial, sala}, _from, state) do
    case Map.fetch(state, sala) do
      {:ok, mensajes} -> {:reply, {:ok, Enum.reverse(mensajes)}, state}
      :error -> {:reply, {:error, :sala_no_encontrada}, state}
    end
  end

  @impl true
  @doc """
  Lista todas las salas registradas.
  """
  def handle_call(:listar_salas, _from, state) do
    {:reply, Map.keys(state), state}
  end

  @impl true
  @doc """
  Restablece el estado dejando solo la sala 'general'.
  """
  def handle_call(:reset, _from, _state) do
    nuevo_state = %{"general" => []}
    {:reply, :ok, nuevo_state}
  end

  @impl true
  @doc """
  Maneja el envío de un mensaje a una sala y lo difunde por PubSub.
  """
  def handle_cast({:enviar_mensaje, sala, autor, contenido}, state) do
    if Map.has_key?(state, sala) do
      mensaje = Message.new(autor, contenido, sala)
      mensajes_actualizados = [mensaje | Map.get(state, sala)]
      nuevo_state = Map.put(state, sala, mensajes_actualizados)

      Phoenix.PubSub.broadcast(
        Hackathon.PubSub,
        "chat:#{sala}",
        {:nuevo_mensaje, mensaje}
      )

      IO.puts("[#{Node.self()}] Mensaje: [#{sala}] #{autor}: #{contenido}")

      {:noreply, nuevo_state}
    else
      IO.puts("Sala no encontrada: #{sala}")
      {:noreply, state}
    end
  end

  @impl true
  @doc """
  Evento cuando un nodo del cluster se conecta.
  """
  def handle_info({:nodeup, nodo}, state) do
    IO.puts("Nodo conectado: #{nodo}")
    IO.puts("   Cluster: #{inspect([Node.self() | Node.list()])}")
    {:noreply, state}
  end

  @impl true
  @doc """
  Evento cuando un nodo del cluster se desconecta.
  """
  def handle_info({:nodedown, nodo}, state) do
    IO.puts("Nodo desconectado: #{nodo}")
    {:noreply, state}
  end

  @impl true
  @doc """
  Ignora mensajes no manejados.
  """
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
