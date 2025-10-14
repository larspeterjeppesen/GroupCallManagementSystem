FROM elixir:1.18.4
WORKDIR /app
RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get
RUN mix deps.compile

COPY . .

EXPOSE 8080

CMD ["mix", "run", "--no-halt"]
