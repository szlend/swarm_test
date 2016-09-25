defmodule SwarmTest.Server do
  use GenServer

  @max_depth 1000
  @max_pings 100

  # Client

  def start_link(n) do
    GenServer.start_link(__MODULE__, n)
  end

  def process(n) do
    case Swarm.register_name({:swarm_test, n}, __MODULE__, :start_link, [n]) do
      {:ok, pid} -> pid
      {:error, {:already_registered, pid}} -> pid
    end
  end

  def run do
    GenServer.cast(process(0), :run)
  end

  def ping(from_n, to_n) do
    GenServer.cast(process(to_n), {:ping, from_n})
  end

  def pong(from_n, to_n) do
    GenServer.cast(process(to_n), {:pong, from_n})
  end

  def check(n) do
    GenServer.call(process(n), :check)
  end

  def check_all do
    {from, to} = {-@max_depth, @max_depth}
    checks = for n <- from..to, do: check(n)
    Enum.all?(checks)
  end

  # Server

  def init(n) do
    {:ok, %{n: n, pings: 0, pongs: 0}}
  end

  def handle_cast(:run, state) do
    state = ping_neighbours(state)
    {:noreply, state}
  end

  # first ping: reply with pong, and ping the neighbours
  def handle_cast({:ping, from_n}, %{pings: pings} = state) when pings == 0 do
    state = ping_neighbours(state)
    pong(from_n, state.n)
    {:noreply, state}
  end

  # rest ping: just reply with pong
  def handle_cast({:ping, from_n}, state) do
    pong(from_n, state.n)
    {:noreply, state}
  end

  def handle_cast({:pong, from_n}, state) do
    IO.puts("Got pong from: #{from_n}")
    {:noreply, %{state | pongs: state.pongs + 1}}
  end

  def handle_call(:check, _from, state) do
    IO.puts("Process #{state.n}, pings: #{state.pings}, pongs: #{state.pongs}")
    {:reply, state.pings == state.pongs, state}
  end

  def ping_neighbours(state) do
    {from, to} = {state.n - div(@max_pings, 2), state.n + div(@max_pings, 2)}
    pings = for n <- from..to, n != state.n, abs(n) <= @max_depth do
      ping(state.n, n)
    end
    ping_count = Enum.count(pings)
    %{state | pings: ping_count}
  end
end
