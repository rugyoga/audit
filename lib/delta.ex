defmodule Delta do
  @moduledoc "Simple difference engine"

  @type delta() :: {:update, any(), any()} | {:delete, any()} | {:add, any()}
  @type path() :: list()
  @type delta_spec() :: [{path(), delta()}]

  @doc """
  Takes delta between two items

  ## Examples

      iex> Delta.delta(%{ a: 1, b: 2, c: 3}, %{ a: 2, b: 2, d: 4 })
      [
        {[:a], {:update, 1, 2}},
        {[:c], {:delete, 3}},
        {[:d], {:add, 4}}
      ]

      iex> Delta.delta([:a, :b, :c], [:a, :d, :c])
      [
        {[1], {:update, :b, :d}}
      ]

      iex> Delta.delta({:a, :b, :c}, {:a, :d, :c})
      [
        {[1], {:update, :b, :d}}
      ]

      iex> Delta.delta(:apple, :orange)
      [
        {[], {:update, :apple, :orange}}
      ]

      iex> Delta.delta(:apple, :apple)
      []

      iex> Delta.delta("", :orange)
      [
        {[], {:add, :orange}}
      ]

      iex> Delta.delta(:apple, "")
      [
        {[], {:delete, :apple}}
      ]

      iex> Delta.delta({:a, :b, :c}, {:a, :d, :c})
      [
        {[1], {:update, :b, :d}}
      ]

      iex> Delta.delta({:a, :b, :c}, {:a, :b, :c})
      []

      iex> Delta.delta({:a, :b, :c}, {:a, :b, :c, :d})
      [
        {[], {:update, {:a, :b, :c}, {:a, :b, :c, :d}}}
      ]

      iex> Delta.delta([:a, :b, :c], [:a, :d, :c])
      [
        {[1], {:update, :b, :d}}
      ]

      iex> Delta.delta([:a, :b, :c], [:a, :b, :c])
      []

      iex> Delta.delta([:a, :b, :c], [:a, :b, :c, :d])
      [
        {[], {:update, [:a, :b, :c], [:a, :b, :c, :d]}}
      ]

      iex> Delta.delta(%{ a: 1, b: 2, c: 3}, %{ a: 2, b: 2, d: 4 })
      [
        {[:a], {:update, 1, 2}},
        {[:c], {:delete, 3}},
        {[:d], {:add, 4}}
      ]
  """
  @spec delta(any(), any()) :: delta_spec()
  def delta(a, b) do
    []
    |> delta(a, b)
    |> List.flatten()
    |> Enum.map(fn {path, element} -> {Enum.reverse(path), element} end)
    |> Enum.sort_by(fn {path, _} -> {length(path), path} end)
  end

  @spec delta(path(), any(), any()) :: delta_spec()
  defp delta(path, a, b) when is_struct(a) and is_struct(b), do: delta_struct(path, a, b)
  defp delta(path, a, b) when is_map(a) and is_map(b), do: delta_map(path, a, b)
  defp delta(path, a, b) when is_list(a) and is_list(b), do: delta_list(path, a, b)
  defp delta(path, a, b) when is_tuple(a) and is_tuple(b), do: delta_tuple(path, a, b)
  defp delta(path, a, b), do: delta_simple(path, a, b)

  @spec delta_struct(path(), struct(), struct()) :: delta_spec()
  def delta_struct(path, %a_s{} = a, %b_s{} = b) when a_s != b_s, do: delta_simple(path, a, b)
  def delta_struct(path, a, b), do: delta_map(path, Map.from_struct(a), Map.from_struct(b))

  @spec delta_map(path(), map(), map()) :: delta_spec()
  def delta_map(path, a, b) do
    a_keys = MapSet.new(Map.keys(a))
    b_keys = MapSet.new(Map.keys(b))
    common = MapSet.intersection(a_keys, b_keys)
    a_only = a_keys |> MapSet.difference(common) |> Enum.to_list()
    b_only = b_keys |> MapSet.difference(common) |> Enum.to_list()

    Enum.flat_map(Enum.to_list(common), fn key -> delta([key | path], a[key], b[key]) end) ++
      Enum.flat_map(a_only, fn key -> [{[key | path], {:delete, a[key]}}] end) ++
      Enum.flat_map(b_only, fn key -> [{[key | path], {:add, b[key]}}] end)
  end

  @spec delta_list(path(), list(), list()) :: delta_spec()
  defp delta_list(path, as, bs) when length(as) != length(bs), do: delta_simple(path, as, bs)
  defp delta_list(path, as, bs) do
    0..(length(as) - 1)
    |> Enum.to_list()
    |> Enum.zip(Enum.zip(as, bs))
    |> Enum.flat_map(fn {i, {a, b}} -> delta([i | path], a, b) end)
  end

  @spec delta_tuple(path(), tuple(), tuple()) :: delta_spec()
  defp delta_tuple(path, a, b) when tuple_size(a) != tuple_size(b), do: delta_simple(path, a, b)
  defp delta_tuple(path, a, b), do: delta_list(path, Tuple.to_list(a), Tuple.to_list(b))

  @spec delta_simple(path(), term(), term()) :: delta_spec()
  defp delta_simple(_path, a, b) when a == b, do: []
  defp delta_simple(path, a, b) do
    cond do
      boring?(a) -> [{path, {:add, b}}]
      boring?(b) -> [{path, {:delete, a}}]
      true -> [{path, {:update, a, b}}]
    end
  end

  @boring [false, "", nil, [], 0, 0.0]

  @doc """
  Identifies boring values

  ## Examples

    iex> Delta.boring?(false)
    true

    iex> Delta.boring?("")
    true

    iex> Delta.boring?(nil)
    true

    iex> Delta.boring?([])
    true

    iex> Delta.boring?(0)
    true

    iex> Delta.boring?(0.0)
    true

    iex> Delta.boring?([false, "", nil, [], 0, 0.0])
    true

    iex> Delta.boring?(%{a: false, b: "", c: nil, d: [], e: 0, f: 0.0})
    true

    iex> Delta.boring?(%{foo: ""})
    true

    iex> Delta.boring?(%{foo: "185 Berry St"})
    false

    iex> Delta.boring?("boring")
    false
  """
  @spec boring?(any()) :: boolean()
  def boring?(value) when value in @boring, do: true
  def boring?(list = [_ | _]), do: Enum.all?(list, &boring?/1)
  def boring?(struct = %_{}), do: struct |> Map.from_struct() |> boring?()
  def boring?(map = %{}), do: map |> Map.values() |> boring?()
  def boring?(_), do: false
end
