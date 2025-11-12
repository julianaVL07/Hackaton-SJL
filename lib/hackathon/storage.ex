defmodule Hackathon.Storage do
  @moduledoc """
  Módulo encargado de la persistencia de datos del sistema en archivos CSV.

  Este módulo guarda y carga la información relacionada con:
    - Equipos
    - Proyectos
    - Mentores

  Cada tipo de dato se almacena en un archivo CSV independiente dentro de
  `priv/storage`. Se usa JSON para guardar campos que contienen listas o
  estructuras complejas (como participantes o retroalimentaciones).
  """

  # Carpeta donde se almacenan los archivos CSV
  @storage_dir "priv/storage"


  # PERSISTENCIA DE EQUIPOS
  

  @doc """
  Guarda equipos en un archivo CSV (`equipos.csv`).
  Cada fila en CSV guarda:
    id,nombre,tema,participantes_json,creado_en
  """
  def guardar_equipos(equipos) when is_map(equipos) do
    # Asegurar que el directorio existe
    File.mkdir_p!(@storage_dir)
    ruta = Path.join(@storage_dir, "equipos.csv")

    # Definir encabezados del CSV
    encabezados = "id,nombre,tema,participantes_json,creado_en\n"

    # Convertir cada equipo en una línea CSV
    filas =
      equipos
      |> Map.values()
      |> Enum.map(fn equipo ->
        # Los participantes se guardan como JSON para no perder estructura
        participantes_json = Jason.encode!(equipo.participantes)

        [
          equipo.id,
          escapar_csv(equipo.nombre),
          escapar_csv(equipo.tema),
          escapar_csv(participantes_json),
          DateTime.to_iso8601(equipo.creado_en)
        ]
        |> Enum.join(",")
      end)
      |> Enum.join("\n")

    File.write!(ruta, encabezados <> filas <> "\n")
    :ok
  end

  @doc """
  Carga equipos desde `equipos.csv`.

  Retorna:
      {:ok, %{nombre_equipo => %Hackathon.Teams.Team{}}}
      {:error, :not_found} si el archivo no existe
  """
  def cargar_equipos do
    ruta = Path.join(@storage_dir, "equipos.csv")

    case File.read(ruta) do
      {:ok, contenido} ->
        equipos =
          contenido
          |> String.split("\n", trim: true)
          |> Enum.drop(1) # Quitar encabezado
          |> Enum.map(&parsear_equipo/1)
          |> Enum.reject(&is_nil/1)
          |> Map.new(fn equipo -> {equipo.nombre, equipo} end)

        {:ok, equipos}

      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  # PERSISTENCIA DE PROYECTOS

  @doc """
  Guarda proyectos en `proyectos.csv`.

  Se guardan avances y retroalimentaciones como JSON.
  """
  def guardar_proyectos(proyectos) when is_map(proyectos) do
    File.mkdir_p!(@storage_dir)
    ruta = Path.join(@storage_dir, "proyectos.csv")

    encabezados = "id,nombre_equipo,descripcion,categoria,estado,avances_json,retroalimentaciones_json,creado_en\n"

    filas =
      proyectos
      |> Map.values()
      |> Enum.map(fn proyecto ->
        avances_json = Jason.encode!(proyecto.avances)
        retros_json = Jason.encode!(proyecto.retroalimentaciones)

        [
          proyecto.id,
          escapar_csv(proyecto.nombre_equipo),
          escapar_csv(proyecto.descripcion),
          to_string(proyecto.categoria),
          to_string(proyecto.estado),
          escapar_csv(avances_json),
          escapar_csv(retros_json),
          DateTime.to_iso8601(proyecto.creado_en)
        ]
        |> Enum.join(",")
      end)
      |> Enum.join("\n")

    File.write!(ruta, encabezados <> filas <> "\n")
    :ok
  end

  @doc """
  Carga proyectos desde `proyectos.csv`.

  Reconstruye:
    - Fechas en DateTime
    - Listas de avances
    - Retroalimentaciones con fecha
  """
  def cargar_proyectos do
    ruta = Path.join(@storage_dir, "proyectos.csv")

    case File.read(ruta) do
      {:ok, contenido} ->
        proyectos =
          contenido
          |> String.split("\n", trim: true)
          |> Enum.drop(1)
          |> Enum.map(&parsear_proyecto/1)
          |> Enum.reject(&is_nil/1)
          |> Map.new(fn proyecto -> {proyecto.nombre_equipo, proyecto} end)

        {:ok, proyectos}

      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

end
