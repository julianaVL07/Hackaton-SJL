defmodule HackathonTest do
  @moduledoc """
  Conjunto de pruebas integrales para el sistema Hackathon.

  Estas pruebas validan el comportamiento de todos los módulos principales:

    • Gestión de Equipos — creación, unicidad y participantes
    • Gestión de Proyectos — estados, avances y filtrado
    • Sistema de Chat — salas y mensajes
    • Sistema de Mentoría — registro y retroalimentación

  El objetivo es garantizar que las reglas de negocio funcionen
  correctamente y que la aplicación mantenga un estado consistente.
  """

  use ExUnit.Case
  doctest Hackathon

  setup do
    # Reinicia el estado global antes de cada prueba
    :ok = Hackathon.reset()
    :ok
  end


  describe "Gestión de Equipos" do
    @tag :equipos
    test "crear equipo exitosamente" do
      assert {:ok, eq} = Hackathon.crear_equipo("TestTeam", "IA")
      assert eq.nombre == "TestTeam"
      assert eq.tema == "IA"
    end

    test "rechaza equipos duplicados" do
      Hackathon.crear_equipo("TestTeam", "IA")
      assert {:error, :equipo_existente} = Hackathon.crear_equipo("TestTeam", "IA")
    end

    test "agregar participante a un equipo" do
      Hackathon.crear_equipo("TestTeam", "IA")
      assert {:ok, _} = Hackathon.agregar_participante("TestTeam", "Ana", "ana@mail.com")
    end

    test "rechaza participantes con email repetido" do
      Hackathon.crear_equipo("TestTeam", "IA")
      Hackathon.agregar_participante("TestTeam", "Ana", "ana@mail.com")

      assert {:error, :participante_duplicado} =
        Hackathon.agregar_participante("TestTeam", "Ana2", "ana@mail.com")
    end
  end


  describe "Gestión de Proyectos" do
    @tag :proyectos
    test "crear proyecto asociado a un equipo" do
      Hackathon.crear_equipo("TestTeam", "IA")

      assert {:ok, p} = Hackathon.crear_proyecto("TestTeam", "App educativa", :educativo)
      assert p.estado == :iniciado
      assert p.categoria == :educativo
    end

    test "actualizar el estado del proyecto" do
      Hackathon.crear_equipo("TestTeam", "IA")
      Hackathon.crear_proyecto("TestTeam", "App educativa", :educativo)

      assert {:ok, p} = Hackathon.actualizar_estado_proyecto("TestTeam", :en_progreso)
      assert p.estado == :en_progreso
    end

    test "agregar un avance al proyecto" do
      Hackathon.crear_equipo("TestTeam", "IA")
      Hackathon.crear_proyecto("TestTeam", "App educativa", :educativo)

      assert {:ok, p} =
               Hackathon.agregar_avance_proyecto("TestTeam", "Prototipo completado")

      assert length(p.avances) == 1
    end

    test "listar proyectos por categoría" do
      Hackathon.crear_equipo("A", "IA")
      Hackathon.crear_equipo("B", "IoT")

      Hackathon.crear_proyecto("A", "App", :edu)
      Hackathon.crear_proyecto("B", "Sensor", :amb)

      assert length(Hackathon.listar_proyectos_por_categoria(:edu)) == 1
    end
  end

  describe "Sistema de Chat" do
    @tag :chat
    test "crear sala de chat" do
      assert {:ok, _} = Hackathon.crear_sala("Team1")
    end

    test "enviar mensaje a una sala" do
      Hackathon.crear_sala("Team1")
      assert :ok = Hackathon.enviar_mensaje("Team1", "Ana", "Hola!")
    end

    test "obtener historial de una sala" do
      Hackathon.crear_sala("Team1")
      Hackathon.enviar_mensaje("Team1", "Ana", "Primer mensaje")
      Hackathon.enviar_mensaje("Team1", "Luis", "Segundo mensaje")

      assert {:ok, msgs} = Hackathon.obtener_historial("Team1")
      assert length(msgs) == 2
    end
  end

   @doc """
    Verifica que un mentor pueda registrarse con nombre y especialidad válidos.
    """
    describe "Sistema de Mentoría" do
    test "registrar mentor" do
      assert {:ok, mentor} = Hackathon.registrar_mentor("Dr. Smith", "IA")
      assert mentor.nombre == "Dr. Smith"
      assert mentor.especialidad == "IA"
    end

    test "enviar retroalimentación a un equipo" do
      Hackathon.crear_equipo("Team1", "IA")
      Hackathon.crear_proyecto("Team1", "App", :edu)
      {:ok, m} = Hackathon.registrar_mentor("Dr. Smith", "IA")

      assert {:ok, _} = Hackathon.enviar_retroalimentacion(m.id, "Team1", "Buen avance")
    end

    test "retroalimentación queda almacenada en el proyecto" do
      Hackathon.crear_equipo("Team1", "IA")
      Hackathon.crear_proyecto("Team1", "App", :edu)
      {:ok, m} = Hackathon.registrar_mentor("Dr. Smith", "IA")

      Hackathon.enviar_retroalimentacion(m.id, "Team1", "Excelente trabajo")

      {:ok, p} = Hackathon.obtener_proyecto("Team1")
      assert length(p.retroalimentaciones) == 1
    end
  end
end
