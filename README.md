# GroupCallManagementSystem
Group Call Management System for floor control of audio channels (Motorola Solutions Technical Assignment)

## Introduction

I want to emphasize that I wrote my first line of code in elixir about a week ago, and this is my first project in the language. I hope my code does not look completely horrendous to you elixir veterans :)  

For an overview of the code architecture, see `gcm/README.md`

## How to run
Clone this repository, and from the root folder, run with sudo/admin privilege:  
`docker build -t gcm gcm`  
`docker run -p 8080:8080 gcm`

## API implementation
The OpenAPI spec has been implemented, but note that in order to accomodate for the bonus challenge of implementing prioritized requests, I have modified the description of response 400 for the path `/groups/{groupId}/floor` to be "Bad Request - Missing or invalid parameter" (instead of "Bad Request - Missing or invalid userId").  
(See openapi_spec.txt for my fully updated spec)

## Bonus challenges

### Floor Timeout (Implemented)
Every 500ms the service will check if the current floor holders have held an audio channel for more than 250ms. (This timeout limit is of course absurdly low, but is chosen to speed up testing).

### List floor holder (Implemented)
A get request with path `/groups/{groupId}/floor` has been implemented. See `openapi_spec.txt` for the updated spec.

### Prioritized request (Implemented)
The UserRequest requestBody has been extended to include an optional parameter. Requests sent without including this parameter will automatically be assigned the lowest possible priority. See `openapi_spec.txt` for the updated spec.

### Audit endpoint (Not implemented)
I did not have time to complete this challenge. If I did have time, optimally I would have run a Postgresql database, and sent async messages with insertions to it from GCM.FM on the callbacks that modify the state of the audio channels, as well as a GenServer that can handle async retrievals from the database.  
While more complicated than eg. keeping historical data in memory, it would add persistence across process crashes (the whole service could crash and reboot without any data loss) 

### CI: (Implemented)
I have set up a GitHub Actions workflow to set up a runner which runs all implemented `mix` tests on pushing a commit. See `.github/workflows/elixir.yml` for the workflow.

### Kubernetes deployment (Not implemented)
I did not have time to dive into this challenge.


