defmodule Hackathon.Mentors.Mentor do
  @moduledoc """
  Este módulo define la estructura y funciones asociadas a un **Mentor** dentro
  de la hackathon. Un mentor cuenta con un identificador único, un nombre,
  una especialidad, y una lista de retroalimentaciones que ha realizado.
  """

  # Campos obligatorios al construir un mentor.
  @enforce_keys [:id, :nombre, :especialidad]
  # `retroalimentaciones` comienza como lista vacía.
  defstruct [:id, :nombre, :especialidad, retroalimentaciones: []]

  @typedoc """
  Representa una retroalimentación dada por el mentor a un equipo.
  Contiene el nombre del equipo, el contenido del comentario,
  y la fecha en que fue emitido.
  """
  @type retroalimentacion :: %{
          equipo: String.t(),
          contenido: String.t(),
          fecha: DateTime.t()
        }

  @typedoc """
  Tipo que representa a un mentor.
  """
  @type t :: %__MODULE__{
          id: String.t(),
          nombre: String.t(),
          especialidad: String.t(),
          retroalimentaciones: [retroalimentacion()]
        }

  @doc """
  Crea un nuevo mentor asignándole automáticamente un `id` único.

  ## Parámetros
    - `nombre` (String): Nombre del mentor.
    - `especialidad` (String): Área principal de conocimiento del mentor.
  """
  def new(nombre, especialidad) do
    %__MODULE__{
      id: generar_id(),
      nombre: nombre,
      especialidad: especialidad
    }
  end

  @doc """
  Agrega una retroalimentación nueva al mentor.

  ## Parámetros
    - `mentor` (%Mentor{}): El mentor al que se le agregará la retroalimentación.
    - `equipo` (String): El nombre del equipo que recibe la retroalimentación.
    - `contenido` (String): El mensaje o recomendación dada.

  La fecha se asigna automáticamente usando la hora UTC actual.

  ## Retorna
    - Una nueva versión del mentor con la retroalimentación añadida a la lista.
  """
  def agregar_retroalimentacion(%__MODULE__{} = mentor, equipo, contenido) do
    retroalimentacion = %{
      equipo: equipo,
      contenido: contenido,
      fecha: DateTime.utc_now()
    }

    retroalimentaciones_actualizadas = [retroalimentacion | mentor.retroalimentaciones]
    %{mentor | retroalimentaciones: retroalimentaciones_actualizadas}
  end

  @doc false
  # Genera un id único basado en bytes aleatorios codificados en hexadecimal.
  defp generar_id do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16(case: :lower)
  end
end
