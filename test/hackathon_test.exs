defmodule HackathonTest do
  use ExUnit.Case
  doctest Hackathon

  @doc """
  Configuración inicial que se ejecuta antes de cada prueba.
  En este caso se utiliza para asegurar que cada test comience
  con un estado limpio, evitando interferencia entre pruebas.
  """
  setup do
    :ok
  end


  describe "Gestión de Equipos" do
    @doc """
    Verifica que se pueda crear un equipo correctamente con nombre y tema válidos.
    """
    test "crear equipo exitosamente" do
      assert {:ok, equipo} = Hackathon.crear_equipo("TestTeam", "IA")
      assert equipo.nombre == "TestTeam"
      assert equipo.tema == "IA"
    end



  @doc """
  Verifica que el sistema no permita registrar dos equipos con el mismo nombre.
  """
    test "no permite equipos duplicados" do
      Hackathon.crear_equipo("TestTeam", "IA")
      assert {:error, :equipo_existente} = Hackathon.crear_equipo("TestTeam", "Blockchain")
    end


    @doc """
    Verifica que se pueda agregar correctamente un participante a un equipo existente.
    """
    test "agregar participante a equipo" do
      Hackathon.crear_equipo("TestTeam", "IA")
      assert {:ok, _} = Hackathon.agregar_participante("TestTeam", "Ana", "ana@test.com")
    end



    @doc """
    Verifica que no se puedan registrar dos participantes con el mismo email
    dentro del mismo equipo.
    """
    test "no permite participantes duplicados por email" do
      Hackathon.crear_equipo("TestTeam", "IA")
      Hackathon.agregar_participante("TestTeam", "Ana", "ana@test.com")

      assert {:error, :participante_duplicado} =
               Hackathon.agregar_participante("TestTeam", "Ana García", "ana@test.com")
    end
  end


  describe "Gestión de Proyectos" do
    @doc """
    Verifica que un proyecto pueda ser creado correctamente para un equipo existente.
    """
    test "crear proyecto exitosamente" do
      Hackathon.crear_equipo("TestTeam", "IA")
      assert {:ok, proyecto} = Hackathon.crear_proyecto("TestTeam", "App educativa", :educativo)
      assert proyecto.categoria == :educativo
      assert proyecto.estado == :iniciado
    end

    @doc """
    Verifica que el estado de un proyecto pueda actualizarse correctamente.
    """
    test "actualizar estado del proyecto" do
      Hackathon.crear_equipo("TestTeam", "IA")
      Hackathon.crear_proyecto("TestTeam", "App educativa", :educativo)

      assert {:ok, proyecto} = Hackathon.actualizar_estado_proyecto("TestTeam", :en_progreso)
      assert proyecto.estado == :en_progreso
    end

    @doc """
    Verifica que se puedan agregar avances al proyecto y que se almacenen correctamente.
    """
    test "agregar avances al proyecto" do
      Hackathon.crear_equipo("TestTeam", "IA")
      Hackathon.crear_proyecto("TestTeam", "App educativa", :educativo)

      assert {:ok, proyecto} =
               Hackathon.agregar_avance_proyecto("TestTeam", "Prototipo completado")

      assert length(proyecto.avances) == 1
    end

    @doc """
    Verifica que el sistema pueda listar proyectos según su categoría.
    """
    test "listar proyectos por categoría" do
      Hackathon.crear_equipo("Team1", "IA")
      Hackathon.crear_equipo("Team2", "IoT")
      Hackathon.crear_proyecto("Team1", "App educativa", :educativo)
      Hackathon.crear_proyecto("Team2", "Sensor ambiental", :ambiental)

      proyectos = Hackathon.listar_proyectos_por_categoria(:educativo)
      assert length(proyectos) == 1
    end
  end

  describe "Sistema de Chat" do
    @doc """
    Verifica que se pueda crear una sala de chat para un equipo.
    """
    test "crear sala de chat" do
      assert {:ok, _} = Hackathon.crear_sala("TestTeam")
    end

     @doc """
    Verifica que un usuario pueda enviar mensajes correctamente a una sala existente.
    """
    test "enviar mensaje a sala" do
      Hackathon.crear_sala("TestTeam")
      assert :ok = Hackathon.enviar_mensaje("TestTeam", "Ana", "Hola equipo")
    end

  end

end
