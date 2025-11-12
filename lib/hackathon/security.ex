defmodule Hackathon.Security do
  @moduledoc """
  Módulo de seguridad para cifrado y descifrado de mensajes del chat.

  Utiliza el algoritmo de cifrado simétrico **AES-256-GCM**
  para garantizar la confidencialidad e integridad de los datos transmitidos.
  """

  @aad "hackathon_chat"

  @doc """
  Cifra un mensaje usando el algoritmo AES-256-GCM.

  Genera un IV (vector de inicialización) aleatorio para cada mensaje
  y devuelve una tupla `{iv, tag, texto_cifrado}` necesaria para descifrarlo.
  """
  def cifrar_mensaje(mensaje, clave) do
    iv = :crypto.strong_rand_bytes(16)

    {texto_cifrado, tag} =
      :crypto.crypto_one_time_aead(
        :aes_256_gcm,
        normalizar_clave(clave),
        iv,
        mensaje,
        @aad,
        true
      )

    {iv, tag, texto_cifrado}
  end

  @doc """
  Descifra un mensaje previamente cifrado con AES-256-GCM.

  Recibe `{iv, tag, texto_cifrado}` junto con la clave usada.
  Retorna `{:ok, mensaje_original}` si el descifrado es exitoso,
  o `{:error, :descifrado_fallido}` si ocurre un error.
  """
  def descifrar_mensaje({iv, tag, texto_cifrado}, clave) do
    case :crypto.crypto_one_time_aead(
           :aes_256_gcm,
           normalizar_clave(clave),
           iv,
           texto_cifrado,
           @aad,
           tag,
           false
         ) do
      mensaje when is_binary(mensaje) ->
        {:ok, mensaje}

      :error ->
        {:error, :descifrado_fallido}
    end
  end

  @doc """
  Codifica los datos cifrados (iv, tag, texto_cifrado)
  a formato *Base64* y los convierte a JSON para almacenamiento o transmisión.
  """
  def codificar({iv, tag, texto_cifrado}) do
    datos = %{
      iv: Base.encode64(iv),
      tag: Base.encode64(tag),
      contenido: Base.encode64(texto_cifrado)
    }

    Jason.encode!(datos)
  end

  @doc """
  Decodifica una cadena JSON en formato Base64 y
  reconstruye la tupla {iv, tag, texto_cifrado} necesaria para descifrar el mensaje.
  """
  def decodificar(json_string) do
    {:ok, datos} = Jason.decode(json_string)

    {
      Base.decode64!(datos["iv"]),
      Base.decode64!(datos["tag"]),
      Base.decode64!(datos["contenido"])
    }
  end

  @doc """
  Normaliza la clave de cifrado para que tenga exactamente 32 bytes (256 bits),
  utilizando un hash SHA-256.
  """
  defp normalizar_clave(clave) when is_binary(clave) do
    :crypto.hash(:sha256, clave)
  end

end
