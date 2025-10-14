defmodule Response do
  def format_response(:obtain, response_code, groupid, userid) do
    case response_code do
      200 -> %{"message" => "Floor obtained by #{userid} for group #{groupid}"}
      {400, :missing_userid} -> %{"message" => "Invalid request: userId is required"}
      {400, :invalid_userid} -> %{"message" => "Invalid request: userId must be a string"}
      {400, :invalid_priority} -> %{"message" => "Invalid request: priority must be a positive integer"}
      409 -> %{"message" => "Floor is currently held by #{userid} for group #{groupid}"}
      r -> raise "unexpected response code #{r}"
    end
  end

  def format_response(:release, response_code, groupid, userid) do
    case response_code do
      200 -> %{"message" => "Floor released by #{userid} for group #{groupid}"}
      403 -> %{"message" => "User #{userid} does not hold the floor for group #{groupid}"}
      r -> raise "unexpected response code #{r}"
    end
  end

  def format_response(:floor_holder, response_code, groupid, userid) do
    case response_code do
      200 -> %{"message" => "The floor of group #{groupid} is currently held by #{userid}"}
      r -> raise "unexpected response code #{r}"
    end
  end
end

defmodule Channel do
  defstruct [:floor_holder, :time_acquired, :priority]
end

defmodule FM do
  # Floor Manager, manages floor holder of audio channels
  use GenServer  

  # Wrappers on callbacks
  
  def start_link(default) do
    GenServer.start_link(__MODULE__, default, name: FloorManager)
  end

  def obtainFloor(groupid, userid, priority) do
    request = {:obtain, groupid, userid, priority || 1}
    GenServer.call(FloorManager, request) 
  end

  def releaseFloor(groupid, userid) do
    request = {:release, groupid, userid}
    GenServer.call(FloorManager, request)
  end

  def getFloorHolder(groupid) do
    request = {:get_floor_holder, groupid}
    GenServer.call(FloorManager, request)
  end
  
  def get_state() do
    GenServer.call(FloorManager, :get_state)
  end

  def reset_state() do
    GenServer.call(FloorManager, :reset)
  end

  def set_state(state) do
    GenServer.call(FloorManager, {:set_state, state})
  end
  
  # Callbacks

  @impl true
  def init(initial_state) when is_map(initial_state) do
    initial_floor_state = initial_state
    {:ok, initial_floor_state}
  end

  defp check_invalid_obtain_parameters(userid, priority) do
    case {userid, priority} do
      {nil, _} -> :missing_userid
      {userid, _} when not is_binary(userid) -> :invalid_userid
      {_, priority} when not is_integer(priority) or priority < 1 -> :invalid_priority
      _ -> :ok
    end
  end

  @impl true
  def handle_call({:obtain, groupid, userid, priority}, _from, floor_state) do
    fmt = &Response.format_response/4
    parameter_status = check_invalid_obtain_parameters(userid, priority)
    if parameter_status != :ok do
      {:reply,
      {400, fmt.(:obtain, {400, parameter_status}, nil, nil)},
      floor_state}    
    else
      case floor_state[groupid] do
        channel when channel == nil or channel.floor_holder == userid or channel.priority < priority ->
          c = %Channel{floor_holder: userid, time_acquired: elem(DateTime.now("Europe/Copenhagen"), 1), priority: priority}
          new_floor_state = Map.put(floor_state, groupid, c)
          {:reply,
          {200, fmt.(:obtain, 200, groupid, userid)},
          new_floor_state}
        channel ->
          {:reply,
          {409, fmt.(:obtain, 409, groupid, channel.floor_holder)},
          floor_state}
      end
    end
  end
  
  def handle_call({:release, groupid, userid}, _from, floor_state) do
    fmt = &Response.format_response/4
    case floor_state[groupid] do
      channel when channel == nil or channel.floor_holder != userid ->
        {:reply,
        {403, fmt.(:release, 403, groupid, userid)},
        floor_state}
      channel when channel.floor_holder == userid ->
        {:reply,
        {200, fmt.(:release, 200, groupid, userid)},
        Map.delete(floor_state, groupid)}
      _ -> raise "unreachable"
    end
  end

  def handle_call({:get_floor_holder, groupid}, _from, floor_state) do
    fmt = &Response.format_response/4
    floor_holder = case floor_state[groupid] do
      nil -> "nil"
      channel -> channel.floor_holder
    end

    {:reply,
    {200, fmt.(:floor_holder, 200, groupid, floor_holder)},
    floor_state}      
  end

  def handle_call(:get_state, _from, floor_state) do
    {:reply, floor_state, floor_state}
  end
 
  def handle_call(:reset, _from, _floor_state) do
    {:reply, "floor state reset to initial", %{}}
  end

  def handle_call({:set_state, new_state}, _from, _floor_state) when is_map(new_state) do
    {:reply, "new floor state set", new_state}
  end  
end

defmodule Timeout do
  # Responsible for auto-releasing floor holders after a given period 
  use GenServer

  def start_link(default) do
    GenServer.start_link(__MODULE__, default)
  end

  defp schedule_next_timeout_check(timer_interval) do
    Process.send_after(self(), :work, timer_interval)
  end

  # Callbacks

  @impl true
  def init({timer_interval, timeout_period}) when is_integer(timer_interval) and is_integer(timeout_period) do
    schedule_next_timeout_check(timer_interval)
    {:ok, {timer_interval, timeout_period}}
  end

  @impl true
  def handle_info(:work, {timer_interval, timeout_period}) do

    {:ok, current_time} = DateTime.now("Europe/Copenhagen")
    current_state = FM.get_state()
    release_cond = fn channel -> DateTime.diff(current_time, elem(channel, 1).time_acquired) > timeout_period/1000 end

    channel_list = Map.to_list(current_state)
    should_update_channels = channel_list
    |> Enum.filter(release_cond)
    |> length() > 0

    if should_update_channels do
      new_state = channel_list
      |> Enum.reject(release_cond)
      |> Enum.reduce(%{}, fn {key,value}, acc -> Map.put(acc, key, value) end)
      FM.set_state(new_state)    
    end
    schedule_next_timeout_check(timer_interval)

    {:noreply, {timer_interval, timeout_period}}
  end

end  
