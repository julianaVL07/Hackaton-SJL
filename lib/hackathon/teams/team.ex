defmodule Hackathon.Teams.Team do
  @moduledoc """
  Maneja la creación de equipos y la gestión de sus participantes en la hackathon.
  """

  @enforce_keys [:id, :nombre, :tema]
  defstruct [:id, :nombre, :tema, participantes: [], creado_en: nil]

  @typedoc "Datos de un participante."
  @type participante :: %{nombre: String.t(), email: String.t()}

  @typedoc "Estructura de un equipo."
  @type t :: %__MODULE__{
          id: String.t(),
          nombre: String.t(),
          tema: String.t(),
          participantes: [participante()],
          creado_en: DateTime.t()
        }

  @doc """
  Crea un nuevo equipo con nombre y tema.
  """
  def new(nombre, tema) do
    %__MODULE__{
      id: generar_id(),
      nombre: nombre,
      tema: tema,
      creado_en: DateTime.utc_now()
    }
  end

  @doc """
  Agrega un participante si su email no existe.
  Retorna {:ok, equipo} o {:error, :participante_duplicado}.
  """
  def agregar_participante(%__MODULE__{} = equipo, nombre, email) do
    participante = %{nombre: nombre, email: email}

    if Enum.any?(equipo.participantes, &(&1.email == email)) do
      {:error, :participante_duplicado}
    else
      {:ok, %{equipo | participantes: [participante | equipo.participantes]}}
    end
  end

  @doc """
  Genera un ID aleatorio para el equipo.
  """
  defp generar_id do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16(case: :lower)
  end
end
