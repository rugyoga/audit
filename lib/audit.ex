defmodule Audit do
  @moduledoc """
    An implementation of Guy's value chain methodology for debugging complex functional programs
  """
  @key :__audit_trail__
  @audit? Application.compile_env(:dora, :audit, false)

  @type file_t :: binary()
  @type line_t :: non_neg_integer()
  @type trail_t(t) :: {t, file_t(), line_t()}

  @spec audit_fun(struct(), Macro.Env) :: struct()
  def audit_fun(r, e) do
    r |> Map.put(@key, payload(r, e))
  end

  @spec unaudit_fun(struct()) :: struct()
  def unaudit_fun(r) do
    r |> Map.delete(@key)
  end

  @spec payload(t, Macro.Env) :: trail_t(t) when t: var
  def payload(r, e), do: {r, e.file, e.line}

  @spec record(trail_t(t)) :: t when t: var
  def record({r, _, _}), do: r

  @spec file(trail_t(term)) :: file_t()
  def file({_, f, _}), do: f

  @spec line(trail_t(term)) :: line_t()
  def line({_, _, l}), do: l

  def trail(struct), do: struct |> Map.get(@key)

  def nth(r, 0), do: r
  def nth(r, n), do: nth(r |> trail |> record, n - 1)

  defp stringify_change({post, {pre, filename, line}}) do
    diff  = Delta.delta(pre |> unaudit_fun, post |> unaudit_fun)
    file  = FileCache.get(filename)
    start = file |> Enum.drop(line-6)
    code  = start |> Enum.drop(5) |> List.first()
    (["#{filename}:#{line}\n", code, "diff: #{inspect(diff)}"]) |> Enum.join()
  end

  defp changelist(r) do
    audit_trail = trail(r)
    if audit_trail, do: [{r, audit_trail} | changelist(record(audit_trail))], else: []
  end

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

  defmacro audit(record) do
    if @audit? do
      quote generated: true do
        unquote(__MODULE__).audit_fun(unquote(record), __ENV__)
      end
    else
      quote do
        unquote(record)
      end
    end
  end
end
