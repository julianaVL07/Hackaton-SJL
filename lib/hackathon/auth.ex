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
end
