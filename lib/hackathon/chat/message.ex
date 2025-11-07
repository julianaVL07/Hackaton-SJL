defmodule Hackathon.Chat.Message do
  @moduledoc """
  Representa un mensaje dentro del sistema de chat.
  """

  #Define que los campos `:autor`, `:contenido` y `:sala` son obligatoriosal crear una estructura de mensaje.
  @enforce_keys [:autor, :contenido, :sala]

  #Estructura que almacena los datos de un mensaje `:id`, `:autor`, `:contenido`, `:sala` y `:timestamp`.
  defstruct [:id, :autor, :contenido, :sala, :timestamp]

  #Tipo que describe la forma que tiene un mensaje en el sistema.
  @type t :: %__MODULE__{
          id: String.t(),
          autor: String.t(),
          contenido: String.t(),
          sala: String.t(),
          timestamp: DateTime.t()
        }

  #Crea un nuevo mensaje con autor, contenido y sala.
  def new(autor, contenido, sala) do
    %__MODULE__{
      id: generar_id(),
      autor: autor,
      contenido: contenido,
      sala: sala,
      timestamp: DateTime.utc_now()
    }
  end

  #Genera un identificador único para el mensaje.
  defp generar_id do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16(case: :lower)
  end
end
