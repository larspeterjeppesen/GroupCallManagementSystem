# GCM

A service for managing floor control of audio channels in groups. This is not a real service, and only simulates floor control.


## How to run
`mix deps.get`
`mix run --no-halt`

The service will then serve requests on 127.0.0.1:8080

### Testing
To run implemented tests of the code, run:
`mix test`


## Architecture
The service consists of:
- A Plug router for receiving and sending requests
- An FM (FloorManager) GenServer that will maintain and mutate state based on incoming requests
- A Timeout GenServer that will, at 500 ms intervals, drop floor holders that have held the floor for more thon 250 ms.

All three processes are supervised, as can be seen in `lib/gcm/application.ex`
