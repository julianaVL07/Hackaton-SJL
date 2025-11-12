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

end
