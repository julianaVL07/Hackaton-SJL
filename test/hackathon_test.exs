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


end
