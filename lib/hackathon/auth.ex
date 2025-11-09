defmodule Hackathon.Auth do
  @moduledoc """
  Módulo de autenticación para los participantes de la hackathon.

  Gestiona el registro, inicio de sesión, validación y cierre de sesión
  mediante tokens de acceso usando un proceso `GenServer`.
  """
  # Permite manejar el estado y las operaciones del módulo mediante un proceso GenServer.
  use GenServer

  # API Pública

  @doc """
  Inicia el proceso de autenticación.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Registra un nuevo participante y genera un token de sesión.

  Retorna `{:ok, token}` si el registro es exitoso.
  """
  def registrar(email, password, nombre) do
    GenServer.call(__MODULE__, {:registrar, email, password, nombre})
  end

  @doc """
  Autentica un participante y retorna un token válido si las credenciales son correctas.
  """
  def login(email, password) do
    GenServer.call(__MODULE__, {:login, email, password})
  end

  @doc """
  Verifica si un token de sesión es válido.
  """
  def validar_token(token) do
    GenServer.call(__MODULE__, {:validar_token, token})
  end

  @doc """
  Cierra la sesión e invalida el token (identificador único) asociado.
  """
  def logout(token) do
    GenServer.call(__MODULE__, {:logout, token})
  end

  # Callbacks del GenServer

  @doc """
  Inicia el estado del servidor con mapas vacíos para usuarios y tokens.
  """
  @impl true
  def init(_) do
    {:ok, %{usuarios: %{}, tokens: %{}}}
  end

  @doc """
  Registra un nuevo usuario.

  Genera un hash (Un hash es una representación única de un dato) de la contraseña y un token asociado.
  Devuelve `{:ok, %{token, email, nombre}}` si es exitoso,
  o `{:error, :usuario_existente}` si el correo ya está registrado.
  """
  @impl true
  def handle_call({:registrar, email, password, nombre}, _from, state) do
    if Map.has_key?(state.usuarios, email) do
      {:reply, {:error, :usuario_existente}, state}
    else
      password_hash = hash_password(password)
      usuario = %{password_hash: password_hash, nombre: nombre}

      usuarios = Map.put(state.usuarios, email, usuario)
      token = generar_token()
      tokens = Map.put(state.tokens, token, email)

      nuevo_state = %{usuarios: usuarios, tokens: tokens}
      {:reply, {:ok, %{token: token, email: email, nombre: nombre}}, nuevo_state}
    end
  end

  @doc """
  Inicia sesión de un usuario.

  Verifica correo y contraseña. Si son correctos, genera un nuevo token.
  Devuelve `{:ok, %{token, email, nombre}}` o un error si falla la autenticación.
  """
  @impl true
  def handle_call({:login, email, password}, _from, state) do
    case Map.fetch(state.usuarios, email) do
      {:ok, usuario} ->
        if verificar_password(password, usuario.password_hash) do
          token = generar_token()
          tokens = Map.put(state.tokens, token, email)
          {:reply, {:ok, %{token: token, email: email, nombre: usuario.nombre}}, %{state | tokens: tokens}}
        else
          {:reply, {:error, :credenciales_invalidas}, state}
        end

      :error ->
        {:reply, {:error, :usuario_no_encontrado}, state}
    end
  end

  @doc """
  Valida si un token pertenece a un usuario registrado.

  Devuelve `{:ok, %{email, nombre}}` si es válido o `{:error, :token_invalido}` si no existe.
  """
  @impl true
  def handle_call({:validar_token, token}, _from, state) do
    case Map.fetch(state.tokens, token) do
      {:ok, email} ->
        usuario = Map.get(state.usuarios, email)
        {:reply, {:ok, %{email: email, nombre: usuario.nombre}}, state}

      :error ->
        {:reply, {:error, :token_invalido}, state}
    end
  end

  @doc """
  Cierra sesión del usuario eliminando su token activo.
  """
  @impl true
  def handle_call({:logout, token}, _from, state) do
    nuevo_state = %{state | tokens: Map.delete(state.tokens, token)}
    {:reply, :ok, nuevo_state}
  end


  # Funciones privadas


  @doc """
  Genera el hash SHA256 de la contraseña.
  """
  defp hash_password(password) do
    :crypto.hash(:sha256, password) |> Base.encode16(case: :lower)
  end

  @doc """
  Verifica que el hash de la contraseña coincida con el almacenado.
  """
  defp verificar_password(password, hash) do
    hash_password(password) == hash
  end

  @doc """
  Genera un token aleatorio de 32 bytes codificado en hexadecimal.
  """
  defp generar_token do
    :crypto.strong_rand_bytes(32) |> Base.encode16(case: :lower)
  end
end
