defmodule Audit.Github do
  def git(args) do
    case System.cmd("git", args) do
    {s, 0} -> String.trim(s)
    _ -> nil
    end
  end

  def git_url(filename, line) do
    base = git(~w(rev-parse --abbrev-ref HEAD))
            |> then(&git(["config", "branch.#{&1}.remote"]))
            |> then(&git(["remote", "get-url", &1]))
            |> String.replace(":", "/")
            |> String.replace("git@", "https://")
            |> String.replace("\.git", "")
    commit_hash = git(["log", "-n1", ~s(--format=format:"%H"), filename])
                  |> String.replace("\"", "")
    "#{base}/blob/#{commit_hash}/#{filename}L#{line}"
  end
end
