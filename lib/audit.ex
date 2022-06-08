defmodule Audit do
  @moduledoc """
    An implementation of Guy's value chain methodology for debugging complex functional programs
  """
  @key :__audit_trail__
  @enabled? Application.compile_env(:audit, :enabled?, false)

  @type file_t :: binary()
  @type line_t :: non_neg_integer()
  @type trail_t :: {struct(), file_t(), line_t()}
  @type change_t :: {struct(), trail_t()}

  def start(_type, _args) do
    Supervisor.start_link([Audit.FileCache], strategy: :one_for_one)
  end

  @dialyzer {:nowarn_function, audit_fun: 2}
  @spec audit_fun(struct(), Macro.Env) :: struct()
  def audit_fun(r, e) do
    r |> struct([{@key, payload(r, e)}])
  end

  @spec unaudit_fun(struct()) :: map()
  def unaudit_fun(r) do
    r |> Map.delete(@key)
  end

  @spec payload(struct(), Macro.Env) :: trail_t()
  def payload(r, e), do: {r, e.file, e.line}

  @spec record(trail_t()) :: struct
  def record({r, _, _}), do: r
  def record(_), do: nil

  @spec file(trail_t()) :: file_t()
  def file({_, f, _}), do: f

  @spec line(trail_t()) :: line_t()
  def line({_, _, l}), do: l

  @spec trail(struct()) :: trail_t() | nil
  def trail(struct), do: struct.__audit_trail__

  @spec nth(struct(), non_neg_integer()) :: struct()
  def nth(r, 0), do: r
  def nth(r, n), do: nth(r |> trail |> record, n - 1)

  @spec stringify_change(change_t()) :: binary()
  defp stringify_change({post, {pre, filename, line}}) do
    diff = Audit.Delta.delta(unaudit_fun(pre), unaudit_fun(post))
    code = Audit.FileCache.get(filename) |> Enum.at(line - 1)
    filename = String.replace_prefix(filename, Audit.Github.git_root())
    url = Audit.Github.git_url(filename, line)
    [url, "#{filename}:#{line}", code, "diff: #{inspect(diff)}"] |> Enum.join("\n")
  end

  @spec changelist(term) :: [change_t()]
  defp changelist(r = %_{__audit_trail__: audit_trail}) do
    if audit_trail, do: [{r, audit_trail} | changelist(record(audit_trail))], else: []
  end

  defp changelist(_), do: []

  @spec to_string(struct) :: binary()
  def to_string(r) do
    r
    |> changelist()
    |> Enum.map_join("\n=====\n", &stringify_change/1)
  end

  defmacro __using__(_opts) do
    quote do
      import Audit
    end
  end

  defmacro audit_real(record) do
    quote generated: true do
      Audit.audit_fun(unquote(record), __ENV__)
    end
  end

  if @enabled? do
    defmacro audit(record) do
      quote generated: true do
        unquote(__MODULE__).audit_fun(unquote(record), __ENV__)
      end
    end
  else
    defmacro audit(record) do
      quote generated: true do
        unquote(record)
      end
    end
  end
end
