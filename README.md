# ![Ruby](./images/ruby-logo.png) Ruby W3C Trace Context - PoC Server Setup

The PoC server setup creates a stack of 30 instrumented servers inside a docker container. 

A third of the servers are instrumented with the  "Legacy" AppOptics Ruby Agent (L), a third of the servers are instrumented with the W3C Trace Context enabled AppOptics Ruby Agent (A) and a third are instrumented using the Open Telemetry Ruby Agent (O). The AppOptics agents report to the AppOptics backend while the Open Telemetry agent reports to a local Zipkin instance. 

The setup allows to interactively bounce requests between the servers using the request path to create complex tracing scenarios.

## Before

This setup is dependent on https://github.com/appoptics/appoptics-apm-ruby being in a sibling directory.
Clone this and that repos first.

```
.
..
appoptics-apm-ruby
ruby-w3c-poc
```

In the Agent repo checkout main_nh branch: `git checkout main_nh`

## Setup

1. Create a `.env` file at the root of the project (ruby-w3c-poc) with the following keys:

  * required: `APPOPTICS_SERVICE_KEY={api-key}:{service-name}`
  * optional: `APPOPTICS_COLLECTOR=collector-stg.appoptics.com`
  * required: `OTEL_EXPORTER_OTLP_ENDPOINT=http://host.docker.internal:4318`
  * required: `OTEL_PROPAGATORS=tracecontext`

2. From the root of the project ` ./start.sh` - this will:
- Build the gem for the  W3C Trace Context enabled AppOptics Ruby Agent 
- Start the servers 
- Open a shell prompt to the container. 

Note that servers are started one by one, so this may take a while.

## Use

Chains of requests are defined using the path and the three Letters `A`, `O`, `L`.

Chains originating at port 4000 must start with 'A'.

Chains originating at port 4100 must start with 'O'.

Chains originating at port 4200 must start with 'L'.


### From Command Line

```
curl -i -X GET http://localhost:4000/AAA
curl -i -X GET http://localhost:4100/OAO
curl -i -X GET http://localhost:4200/LAOAL
```

### From Browser

```
http://localhost:4000/AAA
http://localhost:4100/OAO
http://localhost:4200/LAOAL
```

## Traces

### UI

Traces will be available for viewing at:
* https://my-stg.appoptics.com/ service name (`w3c-poc`)
* http://localhost:9411/zipkin/ (zipkin) and http://localhost:16686/ (Jaeger)

### Logs

Request log for each server stack of instrumented servers is at the root of the respective stack.
```
tail -F appoptics-w3c/req.log
tail -F otel/req.log
tail -F appoptics-legacy/req.log
```
Logs are deleted each time the servers start.

## Using in the Ruby Agent Dev Environment

The gem for the W3C Trace Context enabled AppOptics Ruby Agent is installed from path. Changing code will effect the instrumented services on ports 4000 to 4009 but will require a server restart.

To restart a server, first kill it: 
- List process using `ps aux`.
- Find the server you want to work with based on the port they are on (e.g `root      1167  0.6  0.9 899020 40028 ?        Sl   16:41   0:00 puma 5.5.2 (tcp://0.0.0.0:4001) [appoptics-w3c]`).
- Kill the process (e.g. `kill 1167`)

Then manually start server in the foreground:
- cd into the directory (e.g. `appoptics-w3c`)
- Start the server `bundle exec ruby single.rb {port}` (e.g. `bundle exec ruby single.rb 4001`)
- Exit with Ctrl-C

## Troubleshooting

* When failures happen during the start sequence, containers and ports might be "left hanging". Use `docker kill $(docker ps -a)` to forcefully clean the environment. 
* To clear a hanging port use `lsof -t -i tcp:{port} | xargs kill` (e.g. `lsof -t -i tcp:4200 | xargs kill`). Prepare for Docker desktop crashes....
* To manually interact with server open a new shell `docker exec -it {container id} bash`. 

###### Fabriqué au Canada : Made in Canada 🇨🇦
