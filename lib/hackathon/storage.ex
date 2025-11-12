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
  Se guardan avances y retroalimentaciones.
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
  Reconstruye: Fechas en DateTime, Listas de avances y Retroalimentaciones con fecha
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

  # ---------------------------------------------------------------------------
  # PERSISTENCIA DE MENTORES
  # ---------------------------------------------------------------------------

  @doc """
  Guarda mentores en mentores.csv.
  Las retroalimentaciones se almacenan.
  """
  def guardar_mentores(mentores) when is_map(mentores) do
    File.mkdir_p!(@storage_dir)
    ruta = Path.join(@storage_dir, "mentores.csv")

    encabezados = "id,nombre,especialidad,retroalimentaciones_json\n"

    filas =
      mentores
      |> Map.values()
      |> Enum.map(fn mentor ->
        retros_json = Jason.encode!(mentor.retroalimentaciones)

        [
          mentor.id,
          escapar_csv(mentor.nombre),
          escapar_csv(mentor.especialidad),
          escapar_csv(retros_json)
        ]
        |> Enum.join(",")
      end)
      |> Enum.join("\n")

    File.write!(ruta, encabezados <> filas <> "\n")
    :ok
  end

  @doc """
  Carga mentores desde mentores.csv.
  """
  def cargar_mentores do
    ruta = Path.join(@storage_dir, "mentores.csv")

    case File.read(ruta) do
      {:ok, contenido} ->
        mentores =
          contenido
          |> String.split("\n", trim: true)
          |> Enum.drop(1)
          |> Enum.map(&parsear_mentor/1)
          |> Enum.reject(&is_nil/1)
          |> Map.new(fn mentor -> {mentor.id, mentor} end)

        {:ok, mentores}

      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  # ---------------------------------------------------------------------------
  # FUNCIONES PRIVADAS DE PARSEO CSV
  # ---------------------------------------------------------------------------

  # Convierte línea CSV - struct Equipo
  defp parsear_equipo(linea) do
    case String.split(linea, ",") do
      [id, nombre, tema, participantes_json, creado_en] ->
        {:ok, participantes} = Jason.decode(desescapar_csv(participantes_json))
        {:ok, fecha, _} = DateTime.from_iso8601(creado_en)

        %Hackathon.Teams.Team{
          id: id,
          nombre: desescapar_csv(nombre),
          tema: desescapar_csv(tema),
          participantes: atomizar_participantes(participantes),
          creado_en: fecha
        }

      _ -> nil
    end
  rescue
    _ -> nil
  end

  # Convierte línea CSV → struct Proyecto
  defp parsear_proyecto(linea) do
    case String.split(linea, ",") do
      [id, nombre_equipo, descripcion, categoria, estado, avances_json, retros_json, creado_en] ->
        {:ok, avances} = Jason.decode(desescapar_csv(avances_json))
        {:ok, retros_raw} = Jason.decode(desescapar_csv(retros_json))
        {:ok, fecha, _} = DateTime.from_iso8601(creado_en)

        retros =
          Enum.map(retros_raw, fn r ->
            {:ok, fecha_retro, _} = DateTime.from_iso8601(r["fecha"])
            %{
              mentor: r["mentor"],
              contenido: r["contenido"],
              fecha: fecha_retro
            }
          end)

        %Hackathon.Projects.Project{
          id: id,
          nombre_equipo: desescapar_csv(nombre_equipo),
          descripcion: desescapar_csv(descripcion),
          categoria: String.to_atom(categoria),
          estado: String.to_atom(estado),
          avances: avances,
          retroalimentaciones: retros,
          creado_en: fecha
        }

      _ -> nil
    end
  rescue
    _ -> nil
  end

  # Convierte línea CSV -> struct Mentor
  defp parsear_mentor(linea) do
    case String.split(linea, ",") do
      [id, nombre, especialidad, retros_json] ->
        {:ok, retros_raw} = Jason.decode(desescapar_csv(retros_json))

        retros =
          Enum.map(retros_raw, fn r ->
            {:ok, fecha, _} = DateTime.from_iso8601(r["fecha"])
            %{
              equipo: r["equipo"],
              contenido: r["contenido"],
              fecha: fecha
            }
          end)

        %Hackathon.Mentors.Mentor{
          id: id,
          nombre: desescapar_csv(nombre),
          especialidad: desescapar_csv(especialidad),
          retroalimentaciones: retros
        }

      _ -> nil
    end
  rescue
    _ -> nil
  end

  # Limpia estructura JSON de participantes
  defp atomizar_participantes(participantes) do
    Enum.map(participantes, fn p ->
      %{
        nombre: p["nombre"],
        email: p["email"]
      }
    end)
  end

  # Escapa comas y comillas en campos CSV
  defp escapar_csv(texto) when is_binary(texto) do
    if String.contains?(texto, [",", "\"", "\n"]) do
      "\"#{String.replace(texto, "\"", "\"\"")}\""
    else
      texto
    end
  end

  # Revierte escape CSV
  defp desescapar_csv(texto) when is_binary(texto) do
    texto
    |> String.trim()
    |> String.trim("\"")
    |> String.replace("\"\"", "\"")
  end

end
