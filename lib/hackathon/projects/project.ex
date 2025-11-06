defmodule Hackathon.Projects.Project do
  @moduledoc """
  Struct que representa un proyecto de hackathon.
  """

  # Define los campos obligatorios que deben proporcionarse al crear un proyecto.
  @enforce_keys [:id, :nombre_equipo, :descripcion, :categoria]

  # Estructura del proyecto con valores por defecto para algunos campos.
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

  # Tipos definidos para mejorar la claridad y la verificacion de tipos.
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

  @doc """
    Crea un nuevo proyecto de hackathon.
    Recibe el nombre del equipo, una descripción y la categoría del proyecto.
    Genera automáticamente un identificador único (`id`) y asigna la fecha de creación actual.
    El estado inicial del proyecto se establece en `:iniciado`.
  """
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

  @doc """
  Actualiza el estado de un proyecto.
  Permite cambiar el estado entre `:iniciado`, `:en_progreso` o `:completado`.
  """
  def actualizar_estado(%__MODULE__{} = proyecto, nuevo_estado)
      when nuevo_estado in [:iniciado, :en_progreso, :completado] do
    %{proyecto | estado: nuevo_estado}
  end

  @doc """
  Agrega un nuevo avance al proyecto.
  Cada avance es una cadena de texto que describe el progreso del equipo.
  Los avances más recientes se agregan al inicio de la lista.
  """
  def agregar_avance(%__MODULE__{} = proyecto, avance) do
    avances_actualizados = [avance | proyecto.avances]
    %{proyecto | avances: avances_actualizados}
  end

  @doc """
  Agrega una retroalimentación de un mentor al proyecto.
  La retroalimentación incluye el nombre del mentor, el contenido del comentario
  y la fecha en la que se registró.
  """
  def agregar_retroalimentacion(%__MODULE__{} = proyecto, mentor_nombre, contenido) do
    retro = %{
      mentor: mentor_nombre,
      contenido: contenido,
      fecha: DateTime.utc_now()
    }

    %{proyecto | retroalimentaciones: [retro | proyecto.retroalimentaciones]}
  end

  # Función privada que genera un identificador único de 8 caracteres en formato hexadecimal.
  defp generar_id do
    :crypto.strong_rand_bytes(4)
    |> Base.encode16(case: :lower)
  end
end
