# socat (unflab build)

socat relays bidirectional data between two addresses, where an address
can be almost anything: a TCP socket, a file, a pipe, a pseudo-terminal,
a program's stdin/stdout, a UNIX socket, or a TLS connection. It is `nc`
with an address grammar instead of a fixed shape.

```sh
# Serve a file once on port 8080
socat TCP-LISTEN:8080,reuseaddr,fork FILE:index.html

# Forward a local port to a remote host
socat TCP-LISTEN:5432,reuseaddr,fork TCP:db.internal:5432

# Talk to an HTTPS server, verifying its certificate
printf 'GET / HTTP/1.0\r\n\r\n' | socat - OPENSSL:example.com:443

# Bridge a serial device to a TCP port
socat /dev/tty.usbserial-1420,raw,b115200 TCP-LISTEN:9600
```

`man socat` documents the full address grammar, and it is worth reading —
the tool's power is almost entirely in that syntax.

## Install

```sh
./install.sh                      # into ~/.local/bin
./install.sh --prefix /usr/local/bin
./install.sh --uninstall
```

## About this build

`brew install socat` pulls in **openssl@3**. This package doesn't:
OpenSSL is compiled from source and linked statically into the binary,
so what you install depends on nothing outside `/usr/lib` and
`/System/`.

TLS works out of the box, certificate verification included — the
bundled OpenSSL reads CA certificates from `/private/etc/ssl/cert.pem`,
macOS's own system bundle. `OPENSSL:host:port,verify=1` accepts a valid
certificate and rejects a hostname mismatch, as it should.

Three binaries ship together, because socat's own man page refers to all
three:

- **`socat`** — the relay itself.
- **`filan`** — reports what a process's file descriptors are connected
  to.
- **`procan`** — reports on the process environment socat is running in.

What's given up: the `READLINE:` address type, which wraps an
interactive program with line editing and history. Supporting it would
mean linking a readline library and reintroducing exactly the kind of
dependency this build exists to avoid. Every other address type is
present.
