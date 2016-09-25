# SwarmTest

## Run benchmark
This will start the benchmark. It spawns a ```SwarmTest.Server``` and lazily starts and pings their neighbours.
```elixir
SwarmTest.Server.run
```

## Check result
To check if all pings got a response, run
```elixir
SwarmTest.Server.check_all
```
