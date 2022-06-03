defmodule Audit.FileCache do
  @moduledoc """
  Simple File cache Agent
  """
  use Agent

  def start_link(_args) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(filename) do
    Agent.get_and_update(
      __MODULE__,
      fn state ->
        if cached = Map.get(state, filename) do
          {cached, state}
        else
          file = File.stream!(filename)
          {file, Map.put(state, filename, file)}
        end
      end
    )
  end
end
