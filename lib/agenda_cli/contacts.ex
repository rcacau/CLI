defmodule AgendaCli.Contacts do
  @required_fields ["name", "company", "phone", "email"]

  def add(contacts, attrs) do
    with :ok <- validate_required_fields(attrs),
         :ok <- validate_phone(attrs["phone"]),
         :ok <- validate_email(attrs["email"]) do
      contact = %{id: new_id(), name: attrs["name"], company: attrs["company"], phone: attrs["phone"], email: attrs["email"]}
      {:ok, contacts ++ [contact]}
    end
  end

  def edit(contacts, id, attrs) when is_integer(id) do
    with :ok <- validate_optional_fields(attrs),
         {:ok, contact} <- show(contacts, id) do
      updated_contact = Map.merge(contact, atomize_keys(attrs))
      updated = contacts |> Enum.map(fn item -> if item.id == id, do: updated_contact, else: item end)
      {:ok, updated}
    else
      :error -> {:error, :invalid_id}
      error -> error
    end
  end

  def edit(_contacts, _id, _attrs), do: {:error, :invalid_id}

  def del(contacts, id) when is_integer(id) do
    if Enum.any?(contacts, fn c -> c.id == id end) do
      {:ok, Enum.reject(contacts, fn c -> c.id == id end)}
    else
      {:error, :not_found}
    end
  end

  def del(_contacts, _id), do: {:error, :invalid_id}

  def show(contacts, id) when is_integer(id) do
    case Enum.find(contacts, fn c -> c.id == id end) do
      nil -> {:error, :not_found}
      contact -> {:ok, contact}
    end
  end

  def show(_contacts, _id), do: {:error, :invalid_id}

  def list(contacts), do: contacts |> Enum.sort_by(& &1.name, :asc)
  def search(contacts, {:name, term}), do: filter_partial(contacts, :name, term)
  def search(contacts, {:phone, term}), do: filter_partial(contacts, :phone, term)
  def search(contacts, {:email, term}), do: filter_partial(contacts, :email, term)

  defp filter_partial(contacts, field, term) do
    normalized_term = normalize(term)

    contacts
    |> Enum.filter(fn contact ->
      contact |> Map.fetch!(field) |> normalize() |> String.contains?(normalized_term)
    end)
  end

  defp normalize(value), do: value |> to_string() |> String.downcase()

  defp validate_required_fields(attrs) do
    missing = Enum.any?(@required_fields, fn field -> blank?(Map.get(attrs, field)) end)
    if missing, do: {:error, :missing_required_fields}, else: :ok
  end

  defp validate_optional_fields(attrs) do
    with :ok <- maybe_validate_phone(attrs), :ok <- maybe_validate_email(attrs), do: :ok
  end

  defp maybe_validate_phone(attrs) do
    case Map.fetch(attrs, "phone") do
      :error -> :ok
      {:ok, phone} -> validate_phone(phone)
    end
  end

  defp maybe_validate_email(attrs) do
    case Map.fetch(attrs, "email") do
      :error -> :ok
      {:ok, email} -> validate_email(email)
    end
  end

  defp validate_phone(phone), do: if(blank?(phone), do: {:error, :empty_phone}, else: :ok)
  defp validate_email(email), do: if(valid_email?(email), do: :ok, else: {:error, :invalid_email})
  defp valid_email?(email) when is_binary(email), do: String.match?(email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
  defp valid_email?(_), do: false

  defp blank?(value) do
    value |> to_string() |> String.trim() |> case do "" -> true; _ -> false end
  end

  defp atomize_keys(attrs) do
    attrs |> Enum.reduce(%{}, fn {key, value}, acc -> Map.put(acc, String.to_atom(key), value) end)
  end

  defp new_id, do: :os.system_time(:millisecond)
end
