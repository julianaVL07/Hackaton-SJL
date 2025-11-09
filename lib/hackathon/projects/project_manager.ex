defmodule Hackathon.Projects.ProjectManager do
  @moduledoc """
  GenServer que administra todos los proyectos de la hackathon.
  Se encarga de crear, actualizar y almacenar los proyectos,
  incluyendo su persistencia en archivos CSV.
  """

  use GenServer
  alias Hackathon.Projects.Project
  alias Hackathon.Storage

  # API PÚBLICA

  @doc """
  Inicia el servidor encargado de gestionar los proyectos.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Crea un nuevo proyecto con su nombre de equipo, descripción y categoría.
  Guarda el proyecto en memoria y en el archivo CSV.
  """
  def crear_proyecto(nombre_equipo, descripcion, categoria) do
    GenServer.call(__MODULE__, {:crear_proyecto, nombre_equipo, descripcion, categoria})
  end

  @doc """
  Actualiza el estado de un proyecto existente.
  Por ejemplo: `:en_progreso`, `:finalizado`, etc.
  """
  def actualizar_estado_proyecto(nombre_equipo, estado) do
    GenServer.call(__MODULE__, {:actualizar_estado, nombre_equipo, estado})
  end

  @doc """
  Agrega un nuevo avance o progreso al proyecto.
  """
  def agregar_avance_proyecto(nombre_equipo, avance) do
    GenServer.call(__MODULE__, {:agregar_avance, nombre_equipo, avance})
  end

  @doc """
  Agrega una retroalimentación de un mentor al proyecto.
  La retroalimentación incluye el nombre del mentor, el contenido del comentario y la fecha.
  """
  def agregar_retroalimentacion_proyecto(nombre_equipo, mentor_nombre, contenido) do
    GenServer.call(
      __MODULE__,
      {:agregar_retroalimentacion, nombre_equipo, mentor_nombre, contenido}
    )
  end

  @doc """
  Obtiene la información completa de un proyecto según su nombre de equipo.
  """
  def obtener_proyecto(nombre_equipo) do
    GenServer.call(__MODULE__, {:obtener_proyecto, nombre_equipo})
  end

  @doc """
  Lista todos los proyectos pertenecientes a una categoría específica.
  """
  def listar_proyectos_por_categoria(categoria) do
    GenServer.call(__MODULE__, {:listar_por_categoria, categoria})
  end

  @doc """
  Lista todos los proyectos que se encuentran en un determinado estado.
  """
  def listar_proyectos_por_estado(estado) do
    GenServer.call(__MODULE__, {:listar_por_estado, estado})
  end

  # CALLBACKS DEL SERVIDOR

  @impl true
  @doc """
  Inicializa el servidor cargando los proyectos desde el archivo CSV.
  Si no existe, empieza con un estado vacío.
  """
  def init(_initial_state) do
    state =
      case Storage.cargar_proyectos() do
        {:ok, data} -> data
        {:error, :not_found} -> %{}
      end

    {:ok, state}
  end

  @impl true
  @doc """
  Registra un nuevo usuario en el sistema.

  - Verifica si el correo ya está registrado.
  - Guarda la contraseña en formato hash.
  - Genera un token de sesión automáticamente.
  """
  def handle_call({:registrar, email, password, nombre}, _from, state) do
    if Map.has_key?(state.usuarios, email) do
      {:reply, {:error, :usuario_existente}, state}
    else
      password_hash = hash_password(password)
      usuario = %{password_hash: password_hash, nombre: nombre}

      usuarios_actualizados = Map.put(state.usuarios, email, usuario)
      nuevo_state = %{state | usuarios: usuarios_actualizados}

      token = generar_token()
      tokens_actualizados = Map.put(nuevo_state.tokens, token, email)
      nuevo_state_final = %{nuevo_state | tokens: tokens_actualizados}

      {:reply, {:ok, %{token: token, email: email, nombre: nombre}}, nuevo_state_final}
    end
  end

  @impl true
  @doc """
  Inicia sesión para un usuario existente.

  - Verifica las credenciales (correo y contraseña).
  - Si son válidas, genera y devuelve un nuevo token de sesión.
  """
  def handle_call({:login, email, password}, _from, state) do
    case Map.fetch(state.usuarios, email) do
      {:ok, usuario} ->
        if verificar_password(password, usuario.password_hash) do
          token = generar_token()
          tokens_actualizados = Map.put(state.tokens, token, email)
          nuevo_state = %{state | tokens: tokens_actualizados}

          {:reply, {:ok, %{token: token, email: email, nombre: usuario.nombre}}, nuevo_state}
        else
          {:reply, {:error, :credenciales_invalidas}, state}
        end

      :error ->
        {:reply, {:error, :usuario_no_encontrado}, state}
    end
  end

  @impl true
  @doc """
  Valida un token activo y devuelve la información del usuario asociado.
  """
  def handle_call({:validar_token, token}, _from, state) do
    case Map.fetch(state.tokens, token) do
      {:ok, email} ->
        usuario = Map.get(state.usuarios, email)
        {:reply, {:ok, %{email: email, nombre: usuario.nombre}}, state}

      :error ->
        {:reply, {:error, :token_invalido}, state}
    end
  end

  @impl true
  @doc """
  Cierra la sesión del usuario eliminando su token activo.
  """
  def handle_call({:logout, token}, _from, state) do
    tokens_actualizados = Map.delete(state.tokens, token)
    nuevo_state = %{state | tokens: tokens_actualizados}
    {:reply, :ok, nuevo_state}
  end

  # FUNCIONES PRIVADAS

  @doc """
  Genera un hash SHA256 para almacenar contraseñas de forma segura.
  """
  defp hash_password(password) do
    :crypto.hash(:sha256, password)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Verifica si la contraseña ingresada coincide con el hash almacenado.
  """
  defp verificar_password(password, password_hash) do
    hash_password(password) == password_hash
  end

  @doc """
  Genera un token único de sesión en formato hexadecimal.
  """
  defp generar_token do
    :crypto.strong_rand_bytes(32)
    |> Base.encode16(case: :lower)
  end

end
