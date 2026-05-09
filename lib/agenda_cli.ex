defmodule AgendaCli do
  alias AgendaCli.Contacts
  alias AgendaCli.Store

  def main(_args) do
    print_welcome()

    Store.load()
    |> loop()
  end

  def loop(contacts) do
    case IO.gets("> ") do
      nil ->
        IO.puts("Encerrando aplicacao.")

      input ->
        input
        |> String.trim()
        |> String.split(~r/\s+/, trim: true)
        |> handle_command(contacts)
        |> next_loop(contacts)
    end
  end

  def handle_command([], contacts), do: {:continue, contacts}
  def handle_command(["exit"], _contacts), do: :exit

  def handle_command(["list"], contacts) do
    contacts
    |> Contacts.list()
    |> print_contacts()

    {:continue, contacts}
  end

  def handle_command(["show", id], contacts) do
    case Contacts.show(contacts, parse_id(id)) do
      {:ok, contact} -> print_contact(contact)
      {:error, :invalid_id} -> IO.puts("ID invalido.")
      {:error, :not_found} -> IO.puts("Contato nao encontrado.")
    end

    {:continue, contacts}
  end

  def handle_command(["del", id], contacts) do
    case Contacts.del(contacts, parse_id(id)) do
      {:ok, updated} -> persist(updated, "Contato removido.")
      {:error, :invalid_id} -> IO.puts("ID invalido."); {:continue, contacts}
      {:error, :not_found} -> IO.puts("Contato nao encontrado."); {:continue, contacts}
    end
  end

  def handle_command(["add" | rest], contacts) do
    with {:ok, attrs} <- parse_contact_flags(rest),
         {:ok, updated} <- Contacts.add(contacts, attrs) do
      persist(updated, "Contato adicionado.")
    else
      {:error, reason} -> IO.puts(error_message(reason)); {:continue, contacts}
    end
  end

  def handle_command(["edit", id | rest], contacts) do
    with parsed_id when is_integer(parsed_id) <- parse_id(id),
         {:ok, attrs} <- parse_contact_flags(rest),
         {:ok, updated} <- Contacts.edit(contacts, parsed_id, attrs) do
      persist(updated, "Contato atualizado.")
    else
      :error -> IO.puts("ID invalido."); {:continue, contacts}
      {:error, reason} -> IO.puts(error_message(reason)); {:continue, contacts}
    end
  end

  def handle_command(["search" | rest], contacts) do
    with {:ok, query} <- parse_search(rest) do
      contacts
      |> Contacts.search(query)
      |> print_contacts()
    else
      {:error, reason} -> IO.puts(error_message(reason))
    end

    {:continue, contacts}
  end

  def handle_command(_unknown, contacts) do
    IO.puts("Comando invalido. Use add, edit, del, show, list, search ou exit.")
    {:continue, contacts}
  end

  def parse_search(tokens) do
    with {:ok, attrs} <- parse_flags(tokens),
         1 <- map_size(attrs),
         {:ok, query} <- search_tuple(attrs) do
      {:ok, query}
    else
      0 -> {:error, :missing_search_param}
      _ -> {:error, :invalid_search_flags}
    end
  end

  defp search_tuple(%{"name" => value}), do: {:ok, {:name, value}}
  defp search_tuple(%{"phone" => value}), do: {:ok, {:phone, value}}
  defp search_tuple(%{"email" => value}), do: {:ok, {:email, value}}
  defp search_tuple(_), do: {:error, :invalid_search_flags}

  defp parse_contact_flags(tokens) do
    with {:ok, attrs} <- parse_flags(tokens),
         true <- map_size(attrs) > 0 do
      {:ok, attrs}
    else
      false -> {:error, :missing_params}
      error -> error
    end
  end

  defp parse_flags(tokens), do: parse_flags(tokens, %{}, nil, [])
  defp parse_flags([], acc, nil, []), do: {:ok, acc}
  defp parse_flags([], _acc, nil, _value_parts), do: {:error, :invalid_flags}

  defp parse_flags([], acc, key, value_parts) do
    case build_value(value_parts) do
      {:ok, value} -> {:ok, Map.put(acc, key, value)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_flags(["--" <> key | rest], acc, nil, []) do
    parse_flags(rest, acc, key, [])
  end

  defp parse_flags(["--" <> key | rest], acc, current_key, value_parts) do
    with {:ok, value} <- build_value(value_parts) do
      parse_flags(rest, Map.put(acc, current_key, value), key, [])
    end
  end

  defp parse_flags([token | rest], acc, key, value_parts) when is_binary(key) do
    parse_flags(rest, acc, key, value_parts ++ [token])
  end

  defp parse_flags(_tokens, _acc, _key, _value_parts), do: {:error, :invalid_flags}
  defp build_value([]), do: {:error, :missing_flag_value}

  defp build_value(parts) do
    parts
    |> Enum.join(" ")
    |> String.trim()
    |> case do
      "" -> {:error, :missing_flag_value}
      value -> {:ok, value}
    end
  end

  defp persist(updated_contacts, ok_message) do
    case Store.save(updated_contacts) do
      :ok -> IO.puts(ok_message); {:continue, updated_contacts}
      {:error, :save_failed} -> IO.puts("Falha ao salvar contacts.json."); {:continue, updated_contacts}
    end
  end

  defp next_loop(:exit, _contacts), do: IO.puts("Ate mais!")
  defp next_loop({:continue, new_contacts}, _contacts), do: loop(new_contacts)

  defp print_welcome do
    IO.puts("Agenda CLI")
    IO.puts("Comandos: add, edit, del, show, list, search, exit")
  end

  defp parse_id(id) do
    case Integer.parse(id) do
      {parsed, ""} -> parsed
      _ -> :error
    end
  end

  defp print_contacts([]), do: IO.puts("Nenhum contato encontrado.")
  defp print_contacts(contacts), do: contacts |> Enum.each(&print_contact/1)

  defp print_contact(contact) do
    IO.puts("[#{contact.id}]")
    IO.puts("Nome: #{contact.name}")
    IO.puts("Empresa: #{contact.company}")
    IO.puts("Telefone: #{contact.phone}")
    IO.puts("Email: #{contact.email}")
    IO.puts("")
  end

  defp error_message(:not_found), do: "Contato nao encontrado."
  defp error_message(:invalid_id), do: "ID invalido."
  defp error_message(:missing_params), do: "Parametros ausentes."
  defp error_message(:missing_required_fields), do: "Campos obrigatorios: --name --company --phone --email."
  defp error_message(:invalid_email), do: "Email invalido."
  defp error_message(:empty_phone), do: "Telefone nao pode ser vazio."
  defp error_message(:missing_search_param), do: "Use search com uma unica flag: --name, --phone ou --email."
  defp error_message(:invalid_search_flags), do: "Busca invalida. Use apenas uma flag entre --name, --phone, --email."
  defp error_message(:missing_flag_value), do: "Flag sem valor."
  defp error_message(:invalid_flags), do: "Flags invalidas."
  defp error_message(_), do: "Erro inesperado."
end
