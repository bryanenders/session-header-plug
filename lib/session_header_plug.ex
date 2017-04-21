defmodule SessionHeaderPlug do
  @moduledoc """
  A plug to handle session headers and session stores.

  The session is accessed via functions on `Plug.Conn`. Headers and session have
  to be fetched with `Plug.Conn.fetch_session/1` before the session can be
  accessed.

  ## Session stores

  See `Plug.Session.Store` for the specification session stores are required to
  implement.

  Client-side session storage (e.g., `Plug.Session.COOKIE`) is inherently
  insecure. Consider using `SessionServerStore`.

  ## Options

    * `:store` - session store module (required)
    * `:key` - session header key (required)

  Additional options can be given to the session store, see the store’s
  documentation for the options it accepts.

  ## Examples

      plug SessionHeaderPlug, store: SessionServerStore, key: "session-id"
  """

  alias Plug.Conn

  @behaviour Plug

  @type config :: %{key: String.t, store: module, store_config: keyword}

  @typep conn :: Plug.Conn.t
  @typep sid :: Plug.Session.Store.sid

  ## Callbacks

  @spec init(keyword) :: config
  def init(opts) do
    key = Keyword.fetch!(opts, :key)
    store = Keyword.fetch!(opts, :store)
    store_config =
      opts
      |> Keyword.drop([:key, :store])
      |> store.init()

    %{key: key, store: store, store_config: store_config}
  end

  @spec call(conn, config) :: Plug.Conn.t
  def call(conn, %{key: key} = config) do
    conn
    |> Conn.put_resp_header("access-control-allow-headers", key)
    |> Conn.put_private(:plug_session_fetch, &fetch_session(&1, config))
  end

  @spec fetch_session(conn, config) :: conn
  defp fetch_session(conn, config) do
    {sid, session} = do_fetch_session(conn, config)
    plug_session = Map.merge(session, Map.get(conn.private, :plug_session, %{}))

    conn
    |> Conn.put_private(:plug_session, plug_session)
    |> Conn.put_private(:plug_session_fetch, :done)
    |> Conn.register_before_send(&before_send(&1, sid, config))
  end

  @spec do_fetch_session(conn, config) :: {sid, map}
  defp do_fetch_session(conn, %{key: key, store: store, store_config: store_config}) do
    if req_sid = :proplists.get_value(key, conn.req_headers, nil) do
      store.get(conn, req_sid, store_config)
    else
      {nil, %{}}
    end
  end

  @spec before_send(conn, sid, config) :: conn
  defp before_send(conn, sid, config) do
    case Map.get(conn.private, :plug_session_info) do
      :renew  -> renew_session(conn, sid, config)
      :drop   -> drop_session(conn, sid, config)
      :write  -> write_session(conn, sid, config)
      :ignore -> conn
      nil     -> conn
    end
  end

  @spec renew_session(conn, sid, config) :: conn
  defp renew_session(conn, sid, config) do
    conn
    |> drop_session(sid, config)
    |> write_session(nil, config)
  end

  @spec drop_session(conn, sid, config) :: conn
  defp drop_session(conn, sid, %{store: store, store_config: store_config}) do
    if sid, do: store.delete(conn, sid, store_config)
    conn
  end

  @spec write_session(conn, sid, config) :: conn
  defp write_session(conn, sid, %{key: key, store: store, store_config: store_config}) do
    value = store.put(conn, sid, conn.private[:plug_session], store_config)

    conn
    |> Conn.put_resp_header(key, value)
    |> Conn.put_resp_header("access-control-expose-headers", key)
  end
end
