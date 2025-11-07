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

  # El estado guarda las salas y sus mensajes: %{nombre_sala => [mensajes]}
  @type state :: %{String.t() => [Message.t()]}

  # API PÚBLICA

  @doc """
  Inicia el servidor del chat con una sala predeterminada llamada `"general"`.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{"general" => []}, name: __MODULE__)
  end

  @doc """
  Crea una nueva sala de chat con el nombre dado.
  Retorna un error si la sala ya existe.
  """
  def crear_sala(nombre_sala) do
    GenServer.call(__MODULE__, {:crear_sala, nombre_sala})
  end

  @doc """
  Envía un mensaje a una sala específica.
  El mensaje se guarda en el historial y se transmite a todos los suscriptores mediante PubSub.
  """
  def enviar_mensaje(sala, autor, contenido) do
    GenServer.cast(__MODULE__, {:enviar_mensaje, sala, autor, contenido})
  end

  @doc """
  Obtiene el historial de mensajes de una sala.
  Retorna los mensajes en orden cronológico (del más antiguo al más reciente).
  """
  def obtener_historial(sala) do
    GenServer.call(__MODULE__, {:obtener_historial, sala})
  end

  @doc """
  Lista los nombres de todas las salas disponibles en el sistema.
  """
  def listar_salas do
    GenServer.call(__MODULE__, :listar_salas)
  end

  @doc """
  Suscribe un proceso a una sala específica.
  El proceso recibirá los mensajes nuevos que se envíen en esa sala.
  """
  def suscribirse(sala) do
    Phoenix.PubSub.subscribe(Hackathon.PubSub, "chat:#{sala}")
  end

  @doc """
  Cancela la suscripción del proceso a una sala.
  Deja de recibir mensajes en tiempo real de esa sala.
  """
  def desuscribirse(sala) do
    Phoenix.PubSub.unsubscribe(Hackathon.PubSub, "chat:#{sala}")
  end

  # CALLBACKS DEL SERVIDOR

  @impl true
  @doc """
  Inicializa el estado del servidor con la sala `"general"` vacía.
  """
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  @doc """
  Maneja la creación de una nueva sala de chat.
  Si ya existe, retorna un error; si no, la agrega al estado.
  """
  def handle_call({:crear_sala, nombre_sala}, _from, state) do
    case Map.has_key?(state, nombre_sala) do
      true ->
        {:reply, {:error, :sala_existente}, state}

      false ->
        nuevo_state = Map.put(state, nombre_sala, [])
        {:reply, {:ok, nombre_sala}, nuevo_state}
    end
  end

  @impl true
  @doc """
  Devuelve el historial de mensajes de una sala.
  Si la sala no existe, retorna un error.
  """
  def handle_call({:obtener_historial, sala}, _from, state) do
    case Map.fetch(state, sala) do
      {:ok, mensajes} ->
        # Retorna mensajes en orden cronológico (los más antiguos primero)
        {:reply, {:ok, Enum.reverse(mensajes)}, state}

      :error ->
        {:reply, {:error, :sala_no_encontrada}, state}
    end
  end

  @impl true
  @doc """
  Devuelve la lista de todas las salas registradas en el servidor.
  """
  def handle_call(:listar_salas, _from, state) do
    salas = Map.keys(state)
    {:reply, salas, state}
  end

  @impl true
  @doc """
  Procesa el envío de un mensaje:
  - Crea el mensaje.
  - Lo agrega al historial de la sala.
  - Lo difunde por PubSub a los usuarios suscritos.
  """
  def handle_cast({:enviar_mensaje, sala, autor, contenido}, state) do
    # Verifica si la sala existe
    case Map.has_key?(state, sala) do
      true ->
        # Crea el mensaje
        mensaje = Message.new(autor, contenido, sala)

        # Agrega el mensaje al historial (al inicio de la lista)
        mensajes_actualizados = [mensaje | Map.get(state, sala)]
        nuevo_state = Map.put(state, sala, mensajes_actualizados)

        # Difunde el mensaje a todos los suscriptores via PubSub
        Phoenix.PubSub.broadcast(
          Hackathon.PubSub,
          "chat:#{sala}",
          {:nuevo_mensaje, mensaje}
        )

        {:noreply, nuevo_state}

      false ->
        # Si la sala no existe, no hace nada
        {:noreply, state}
    end
  end
end
