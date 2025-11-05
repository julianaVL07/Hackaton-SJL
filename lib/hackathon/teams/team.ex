defmodule Hackathon.Teams.Team do
  @moduledoc """
  Struct para representar un equipo de la hackathon.
  """

  @enforce_keys [:id, :nombre, :tema]
  defstruct [:id, :nombre, :tema, participantes: [], creado_en: nil]

  @type participante :: %{nombre: String.t(), email: String.t()}

  @type t :: %__MODULE__{
          id: String.t(),
          nombre: String.t(),
          tema: String.t(),
          participantes: [participante()],
          creado_en: DateTime.t()
        }

  def new(nombre, tema) do
    %__MODULE__{
      id: generar_id(),
      nombre: nombre,
      tema: tema,
      creado_en: DateTime.utc_now()
    }
  end

  def agregar_participante(%__MODULE__{} = equipo, nombre, email) do
    participante = %{nombre: nombre, email: email}

    if Enum.any?(equipo.participantes, fn p -> p.email == email end) do
      {:error, :participante_duplicado}
    else
      participantes_actualizados = [participante | equipo.participantes]
      {:ok, %{equipo | participantes: participantes_actualizados}}
    end
  end

  defp generar_id do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16(case: :lower)
  end
end
