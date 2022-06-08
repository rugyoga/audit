defmodule Audit.Github do
  @moduledoc """
  Helper functions for generating Github URLs from filename and line number
  """

  @type line_number_t :: binary | non_neg_integer()
  @type filename_t :: binary()
  @type git_t :: binary() | nil

  @spec git([binary()]) :: git_t()
  def git(args) do
    case System.cmd("git", args) do
      {s, 0} -> String.trim(s)
      _ -> nil
    end
  end

  @spec git_url(filename_t(), line_number_t()) :: git_t() | nil
  def git_url(filename, line) do
    branch()
    |> remote()
    |> get_url()
    |> to_https()
    |> format_string(commit_hash(), filename, line)
  end

  @spec format_string(git_t(), git_t(), filename_t(), line_number_t()) :: git_t()
  def format_string(nil, _branch, _filename, _line), do: nil
  def format_string(_base, nil, _filename, _line), do: nil

  def format_string(base, branch, filename, line) do
    "#{base}/tree/#{branch}/#{filename}L#{line}"
  end

  @spec branch() :: git_t()
  def branch(), do: git(~w(rev-parse --abbrev-ref HEAD))

  @spec git_root() :: git_t()
  def git_root(), do: git(~w(rev-parse --show-toplevel))

  @spec remote(git_t()) :: git_t()
  def remote(nil), do: nil

  def remote(branch) do
    git(["config", "branch.#{branch}.remote"])
  end

  @spec get_url(git_t()) :: git_t()
  def get_url(nil), do: nil

  def get_url(remote) do
    git(["remote", "get-url", remote])
  end

  @spec to_https(git_t()) :: git_t()
  def to_https(nil), do: nil

  def to_https(get_url) do
    get_url
    |> String.replace(":", "/")
    |> String.replace("git@", "https://")
    |> String.replace("\.git", "")
  end

  @spec commit_hash() :: git_t()
  def commit_hash() do
    git(["log", "-n1", ~s(--format=format:"%H")]) |> String.replace("\"", "")
  end
end
