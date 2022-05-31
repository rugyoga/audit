defmodule Livebook do
  @moduledoc "Collection of utilities for use in Livebooks"

  @doc """
  Identifies boring values

  ## Examples

    iex> Livebook.boring?(false)
    true

    iex> Livebook.boring?("")
    true

    iex> Livebook.boring?(nil)
    true

    iex> Livebook.boring?([])
    true

    iex> Livebook.boring?(0)
    true

    iex> Livebook.boring?(0.0)
    true

    iex> Livebook.boring?([false, "", nil, [], 0, 0.0])
    true

    iex> Livebook.boring?(%{a: false, b: "", c: nil, d: [], e: 0, f: 0.0})
    true

    iex> Livebook.boring?(%{foo: ""})
    true

    iex> Livebook.boring?(%{foo: "185 Berry St"})
    false

    iex> Livebook.boring?("boring")
    false
  """
  @spec boring?(any()) :: boolean()
  def boring?(false), do: true
  def boring?(""), do: true
  def boring?(nil), do: true
  def boring?([]), do: true
  def boring?(0), do: true
  def boring?(0.0), do: true
  def boring?(list = [_ | _]), do: Enum.all?(list, &boring?/1)

  def boring?(struct = %_{}) do
    struct |> Map.from_struct() |> boring?()
  end

  def boring?(map = %{}) do
    map |> Map.to_list() |> Enum.all?(fn {_, v} -> boring?(v) end)
  end

  def boring?(_), do: false

  @doc """
  Identifies boring values

  ## Examples

    iex> Livebook.interesting?("I'm interesting!")
    true
  """
  @spec interesting?(any()) :: boolean()
  def interesting?(x), do: !boring?(x)

  @doc """
  Removes boring values from data

    iex> Livebook.summarize([false, "interesting", 0, "sweet", nil, [:nested, :nonsense]])
    ["interesting", "sweet", [:nested, :nonsense]]

    iex> Livebook.summarize(%{
    ...>       foo: "A value",
    ...>       bar: "",
    ...>       baz: ""
    ...>     })
    %{foo: "A value"}

    iex> Livebook.summarize(%{
    ...>       foo: "",
    ...>       bar: "",
    ...>       baz: ""
    ...>     })
    nil

    iex> Livebook.summarize(%{ a: nil, b: 0, c: false })
    nil

    iex> Livebook.summarize("interesting")
    "interesting"
  """
  @spec summarize(any()) :: any()
  def summarize(list = [_ | _]) do
    list
    |> Enum.map(&summarize/1)
    |> Enum.filter(&interesting?/1)
  end

  def summarize(struct = %sname{}) do
    struct
    |> Map.from_struct()
    |> summarize()
    |> then(fn m -> if m != nil, do: {sname, m} end)
  end

  def summarize(map = %{}) do
    map
    |> Map.to_list()
    |> Enum.map(fn {k, v} -> {k, summarize(v)} end)
    |> Enum.filter(fn {_, v} -> interesting?(v) end)
    |> Enum.into(%{})
    |> then(fn m -> if map_size(m) > 0, do: m end)
  end

  def summarize(x), do: x

  @spec input(String.t()) :: String.t()
  def input(name), do: name |> IO.gets() |> String.trim()

  @doc """
  Takes delta between two structs

  ## Examples
  """
  def delta_struct(path, %a_s{} = a, %b_s{} = b) when a_s != b_s, do: delta_simple(path, a, b)
  def delta_struct(path, a, b), do: delta_map(path, Map.from_struct(a), Map.from_struct(b))

  @doc """
  Takes delta between two maps

  ## Examples

      iex> Livebook.delta_map([], %{ a: 1, b: 2, c: 3}, %{ a: 2, b: 2, d: 4 })
      [
        {[:a], {:different, 1, 2}},
        {[:c], {:left_only, 3}},
        {[:d], {:right_only, 4}}
      ]
  """
  def delta_map(path, a, b) do
    a_keys = MapSet.new(Map.keys(a))
    b_keys = MapSet.new(Map.keys(b))
    common = MapSet.intersection(a_keys, b_keys)
    a_only = a_keys |> MapSet.difference(common) |> Enum.to_list()
    b_only = b_keys |> MapSet.difference(common) |> Enum.to_list()

    Enum.flat_map(Enum.to_list(common), fn key -> delta([key | path], a[key], b[key]) end) ++
      Enum.flat_map(a_only, fn key -> [{[key | path], {:left_only, a[key]}}] end) ++
      Enum.flat_map(b_only, fn key -> [{[key | path], {:right_only, b[key]}}] end)
  end

  @doc """
  Takes delta between two lists

  ## Examples

      iex> Livebook.delta_list([], [:a, :b, :c], [:a, :d, :c])
      [
        {[1], {:different, :b, :d}}
      ]

      iex> Livebook.delta_list([], [:a, :b, :c], [:a, :b, :c])
      []

      iex> Livebook.delta_list([], [:a, :b, :c], [:a, :b, :c, :d])
      [
        {[], {:different, [:a, :b, :c], [:a, :b, :c, :d]}}
      ]
  """
  def delta_list(path, as, bs) when length(as) != length(bs), do: delta_simple(path, as, bs)

  def delta_list(path, as, bs) do
    0..(length(as) - 1)
    |> Enum.to_list()
    |> Enum.zip(Enum.zip(as, bs))
    |> Enum.flat_map(fn {i, {a, b}} -> delta([i | path], a, b) end)
  end

  @doc """
  Takes delta between two tuples

  ## Examples

      iex> Livebook.delta_tuple([], {:a, :b, :c}, {:a, :d, :c})
      [
        {[1], {:different, :b, :d}}
      ]

      iex> Livebook.delta_tuple([], {:a, :b, :c}, {:a, :b, :c})
      []

      iex> Livebook.delta_tuple([], {:a, :b, :c}, {:a, :b, :c, :d})
      [
        {[], {:different, {:a, :b, :c}, {:a, :b, :c, :d}}}
      ]
  """
  def delta_tuple(path, a, b) when tuple_size(a) != tuple_size(b), do: delta_simple(path, a, b)
  def delta_tuple(path, a, b), do: delta_list(path, Tuple.to_list(a), Tuple.to_list(b))

  @doc """
  Takes delta between two items

  ## Examples

      iex> Livebook.delta_simple([], :apple, :orange)
      [
        {[], {:different, :apple, :orange}}
      ]

      iex> Livebook.delta_simple([], :apple, :apple)
      []
  """
  def delta_simple(_path, a, b) when a == b, do: []
  def delta_simple(path, a, b), do: [{path, {:different, a, b}}]

  @doc """
  Takes delta between two items

  ## Examples

      iex> Livebook.delta([], %{ a: 1, b: 2, c: 3}, %{ a: 2, b: 2, d: 4 })
      [
        {[:a], {:different, 1, 2}},
        {[:c], {:left_only, 3}},
        {[:d], {:right_only, 4}}
      ]

      iex> Livebook.delta([], [:a, :b, :c], [:a, :d, :c])
      [
        {[1], {:different, :b, :d}}
      ]

      iex> Livebook.delta([], {:a, :b, :c}, {:a, :d, :c})
      [
        {[1], {:different, :b, :d}}
      ]

      iex> Livebook.delta([], :apple, :orange)
      [
        {[], {:different, :apple, :orange}}
      ]

      iex> Livebook.delta([], :apple, :apple)
      []
  """

  def delta(path, a, b) when is_struct(a) and is_struct(b), do: delta_struct(path, a, b)
  def delta(path, a, b) when is_map(a) and is_map(b), do: delta_map(path, a, b)
  def delta(path, a, b) when is_list(a) and is_list(b), do: delta_list(path, a, b)
  def delta(path, a, b) when is_tuple(a) and is_tuple(b), do: delta_tuple(path, a, b)
  def delta(path, a, b), do: delta_simple(path, a, b)

  @doc """
  Takes delta between two structures

  ## Examples

      iex> Livebook.deltas([{"before", %{ a: 1, b: 2, c: 3}}, {"after", %{ a: 2, b: 2, d: 4 }}])
      [
        {"after",
        [
          {[:a], {:different, 1, 2}},
          {[:c], {:left_only, 3}},
          {[:d], {:right_only, 4}}
        ]}
      ]
  """
  def delta(a, b) do
    []
    |> delta(a, b)
    |> List.flatten()
    |> Enum.map(fn {path, element} -> {Enum.reverse(path), element} end)
    |> Enum.sort_by(fn {path, _} -> {length(path), path} end)
  end

  @type delta() :: {:difference, any(), any()} | {:left_only, any()} | {:right_only, any()}
  @spec deltas([{String.t(), any()}]) :: [{String.t(), delta()}]
  def deltas(stages) do
    stages
    |> Enum.map(fn {label, v} -> {label, summarize(v)} end)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [{_, a}, {label, b}] -> {label, delta(a, b)} end)
  end
end
