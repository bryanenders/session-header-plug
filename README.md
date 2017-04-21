# SessionHeaderPlug

SessionHeaderPlug is a plug to handle session headers and session stores.

[`Plug.Session`](//hexdocs.pm/plug/Plug.Session.html) stores the session
data (whether a session ID or the session itself) in a cookie. While this works
great for server-rendered sites and same origin clients, it fails for
cross-origin clients using modern browser defaults.

You could include the session data in the bodies of your requests and responses,
but this would require significant API design and would either require every
response to include the session data or logic for every response to determine
whether or not to include session data.

SessionHeaderPlug operates just like `Plug.Session`, only it transmits and
receives the session data through a custom header instead of a cookie.

## Installation

Add `session_header_plug` and a session store to your list of dependencies in
mix.exs:

```elixir
defp deps do
  [
    {:session_header_plug, "~> 0.1.0"},
    {:session_server_store, "~> 0.1.0"},
  ]
end
```

## Usage

### Server

1. Plug it in.

```elixir
plug SessionHeaderPlug,
  store: SessionServerStore,
  key: "session-id",
  timeout: 86400,
  idle_timeout: :infinity

plug :fetch_session
```

2. Use the session functions on `Plug.Conn`.

```elixir
conn
|> put_session(:user_id, "admin@somedomain.com")
|> put_session(:admin?, true)
|> json(%{foo: "bar"})
```

### Client

```javascript
const headers = { 'session-id': localStorage.getItem('sid') }

fetch('https://somedomain.com/api/', { headers: headers })
  .then((response) => {
    localStorage.setItem('sid', response.headers.get('session-id'))
  })
```

