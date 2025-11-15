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
end
