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


  #Comit 2
# Título: añadir pruebas para creación básica de equipos
# Descripción: Incluye casos para validar creación exitosa de equipos.
describe "Gestión de Equipos" do
  @doc """
  Verifica que se pueda crear un equipo correctamente con nombre y tema válidos.
  """
  test "crear equipo exitosamente" do
    assert {:ok, equipo} = Hackathon.crear_equipo("TestTeam", "IA")
    assert equipo.nombre == "TestTeam"
    assert equipo.tema == "IA"
  end
end


end
