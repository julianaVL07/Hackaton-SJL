defmodule Hackathon.Chat.ChatServer do
  @moduledoc """
  GenServer que gestiona el sistema de chat con PubSub.
  Versión robusta que maneja conflictos de registro global.
  """

  use GenServer
  alias Hackathon.Chat.Message

  @type state :: %{String.t() => [Message.t()]}

  ## API PÚBLICA

  def start_link(_opts) do
    # Intenta iniciar con registro global
    # Si falla, es porque ya existe uno remoto (está bien)
    case GenServer.start_link(__MODULE__, %{"general" => []}, name: {:global, __MODULE__}) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        # Ya existe un ChatServer global en otro nodo
        IO.puts("Usando ChatServer remoto en nodo #{node(pid)}")
        :ignore
    end
  end

  def crear_sala(nombre_sala) do
    safe_call({:crear_sala, nombre_sala})
  end

  def enviar_mensaje(sala, autor, contenido) do
    safe_cast({:enviar_mensaje, sala, autor, contenido})
  end

  def obtener_historial(sala) do
    safe_call({:obtener_historial, sala})
  end

  def listar_salas do
    safe_call(:listar_salas)
  end

  def reset do
    safe_call(:reset)
  end

  def suscribirse(sala) do
    Phoenix.PubSub.subscribe(Hackathon.PubSub, "chat:#{sala}")
  end

  def desuscribirse(sala) do
    Phoenix.PubSub.unsubscribe(Hackathon.PubSub, "chat:#{sala}")
  end

  def info_cluster do
    %{
      nodo_actual: Node.self(),
      nodos_conectados: Node.list(),
      total_nodos: length(Node.list()) + 1,
      servidor_principal: :global.whereis_name(__MODULE__)
    }
  end

  # Helpers seguros que manejan el caso de ChatServer remoto

  defp safe_call(mensaje, timeout \\ 5000) do
    case :global.whereis_name(__MODULE__) do
      :undefined ->
        {:error, :chat_server_no_disponible}

      pid ->
        GenServer.call(pid, mensaje, timeout)
    end
  rescue
    e -> {:error, {:exception, e}}
  end

  defp safe_cast(mensaje) do
    case :global.whereis_name(__MODULE__) do
      :undefined ->
        {:error, :chat_server_no_disponible}

      pid ->
        GenServer.cast(pid, mensaje)
        :ok
    end
  rescue
    e -> {:error, {:exception, e}}
  end

  ## CALLBACKS

  @impl true
  def init(initial_state) do
    :net_kernel.monitor_nodes(true)

    IO.puts("ChatServer iniciado en nodo: #{Node.self()}")
    IO.puts("   PID global: #{inspect(self())}")

    {:ok, initial_state}
  end

  @impl true
  def handle_call({:crear_sala, nombre_sala}, _from, state) do
    case Map.has_key?(state, nombre_sala) do
      true ->
        {:reply, {:error, :sala_existente}, state}

      false ->
        nuevo_state = Map.put(state, nombre_sala, [])
        IO.puts("Sala creada: #{nombre_sala} en nodo #{Node.self()}")
        {:reply, {:ok, nombre_sala}, nuevo_state}
    end
  end

  @impl true
  def handle_call({:obtener_historial, sala}, _from, state) do
    case Map.fetch(state, sala) do
      {:ok, mensajes} ->
        {:reply, {:ok, Enum.reverse(mensajes)}, state}

      :error ->
        {:reply, {:error, :sala_no_encontrada}, state}
    end
  end

  @impl true
  def handle_call(:listar_salas, _from, state) do
    salas = Map.keys(state)
    {:reply, salas, state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    nuevo_state = %{"general" => []}
    {:reply, :ok, nuevo_state}
  end

  @impl true
  def handle_cast({:enviar_mensaje, sala, autor, contenido}, state) do
    case Map.has_key?(state, sala) do
      true ->
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

      false ->
        IO.puts("Sala no encontrada: #{sala}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:nodeup, nodo}, state) do
    IO.puts("Nodo conectado: #{nodo}")
    IO.puts("   Cluster: #{inspect([Node.self() | Node.list()])}")
    {:noreply, state}
  end

  @impl true
  def handle_info({:nodedown, nodo}, state) do
    IO.puts("Nodo desconectado: #{nodo}")
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
