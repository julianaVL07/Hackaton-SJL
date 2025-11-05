defmodule Hackathon.Projects.Project do
  @moduledoc """
  Struct que representa un proyecto de hackathon.
  """

  @enforce_keys [:id, :nombre_equipo, :descripcion, :categoria]
  defstruct [
    :id,
    :nombre_equipo,
    :descripcion,
    :categoria,
    estado: :iniciado,
    avances: [],
    retroalimentaciones: [],
    creado_en: nil
  ]

  @type estado :: :iniciado | :en_progreso | :completado
  @type categoria :: :social | :ambiental | :educativo
  @type retroalimentacion :: %{
          mentor: String.t(),
          contenido: String.t(),
          fecha: DateTime.t()
        }

  @type t :: %__MODULE__{
          id: String.t(),
          nombre_equipo: String.t(),
          descripcion: String.t(),
          categoria: categoria(),
          estado: estado(),
          avances: [String.t()],
          retroalimentaciones: [retroalimentacion()],
          creado_en: DateTime.t()
        }

  def new(nombre_equipo, descripcion, categoria)
      when categoria in [:social, :ambiental, :educativo] do
    %__MODULE__{
      id: generar_id(),
      nombre_equipo: nombre_equipo,
      descripcion: descripcion,
      categoria: categoria,
      creado_en: DateTime.utc_now()
    }
  end

  def actualizar_estado(%__MODULE__{} = proyecto, nuevo_estado)
      when nuevo_estado in [:iniciado, :en_progreso, :completado] do
    %{proyecto | estado: nuevo_estado}
  end

  def agregar_avance(%__MODULE__{} = proyecto, avance) do
    avances_actualizados = [avance | proyecto.avances]
    %{proyecto | avances: avances_actualizados}
  end

  @doc """
  Agrega una retroalimentación de un mentor al proyecto.
  """
  def agregar_retroalimentacion(%__MODULE__{} = proyecto, mentor_nombre, contenido) do
    retro = %{
      mentor: mentor_nombre,
      contenido: contenido,
      fecha: DateTime.utc_now()
    }

    %{proyecto | retroalimentaciones: [retro | proyecto.retroalimentaciones]}
  end

  defp generar_id do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16(case: :lower)
  end
end
