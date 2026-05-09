defmodule AgendaCli.Store do
  @file_path "contacts.json"

  def load do
    ensure_file_exists()
    @file_path |> File.read() |> decode_contacts()
  end

  def save(contacts) do
    contacts
    |> Jason.encode(pretty: true)
    |> case do
      {:ok, json} ->
        case File.write(@file_path, json) do
          :ok -> :ok
          {:error, _} -> {:error, :save_failed}
        end

      {:error, _} -> {:error, :save_failed}
    end
  end

  defp ensure_file_exists do
    case File.exists?(@file_path) do
      true -> :ok
      false -> File.write(@file_path, "[]")
    end
  end

  defp decode_contacts({:ok, content}) do
    content
    |> String.trim()
    |> case do
      "" -> []
      json ->
        case Jason.decode(json) do
          {:ok, data} when is_list(data) -> Enum.map(data, &to_contact/1)
          _ -> IO.puts("Aviso: contacts.json invalido. Iniciando com lista vazia."); []
        end
    end
  end

  defp decode_contacts({:error, _}), do: []

  defp to_contact(item) do
    %{id: item["id"], name: item["name"], company: item["company"], phone: item["phone"], email: item["email"]}
  end
end
