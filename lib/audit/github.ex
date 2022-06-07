defmodule Audit.Github do
  @moduledoc """
  Helper functions for generating Github URLs from filename and line number
  """

  def git(args) do
    case System.cmd("git", args) do
      {s, 0} -> String.trim(s)
      _ -> nil
    end
  end

  @spec git_url(binary(), binary() | non_neg_integer()) :: binary() | nil
  def git_url(filename, line) do
    branch()
    |> remote()
    |> get_url()
    |> to_https()
    |> format_string(commit_hash(), filename, line)
  end

  @spec format_string(binary() | nil, binary() | nil, binary(), binary() | non_neg_integer()) ::
          binary() | nil
  def format_string(nil, _commit_hash, _filename, _line), do: nil
  def format_string(_base, nil, _filename, _line), do: nil

  def format_string(base, commit_hash, filename, line) do
    "#{base}/blob/#{commit_hash}/#{filename}L#{line}"
  end

  @spec branch() :: binary()
  def branch() do
    git(~w(rev-parse --abbrev-ref HEAD))
  end

  @spec remote(binary() | nil) :: binary() | nil
  def remote(nil), do: nil

  def remote(branch) do
    git(["config", "branch.#{branch}.remote"])
  end

  @spec get_url(binary() | nil) :: binary() | nil
  def get_url(nil), do: nil

  def get_url(remote) do
    git(["remote", "get-url", remote])
  end

  @spec to_https(binary() | nil) :: binary() | nil
  def to_https(nil), do: nil

  def to_https(get_url) do
    get_url
    |> String.replace(":", "/")
    |> String.replace("git@", "https://")
    |> String.replace("\.git", "")
  end

  @spec commit_hash() :: binary() | nil
  def commit_hash() do
    git(["log", "-n1", ~s(--format=format:"%H")]) |> String.replace("\"", "")
  end
end
