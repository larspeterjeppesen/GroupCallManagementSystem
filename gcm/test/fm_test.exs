defmodule FMTest do
  use ExUnit.Case
  doctest FM

  setup do
    FM.reset_state()
    :ok
  end

  # cs = create state 
  def cs(group_user_pairs) do
    Enum.reduce(group_user_pairs, %{}, fn {key,value}, acc -> Map.put(acc, key, value) end) 
  end

  # gup = group user pairs
  def gup(n) when is_integer(n) do
    Enum.to_list(1..n)
    |> Enum.reduce(%{}, fn num, map ->
      num = Integer.to_string(num)
      Map.put(map, "group" <> num, "user" <> num) end)
  end

  test "obtainFloor 200" do
    {status_code, state} = FM.obtainFloor("group1", "user1", nil)
    assert status_code == 200
    assert state == %{"message" => "Floor obtained by user1 for group group1"}
  end

  test "obtainFloor 400 missing userid" do
    {status_code, state} = FM.obtainFloor("group1", nil, nil)
    assert status_code == 400
    assert state == %{"message" => "Invalid request: userId is required"} 
  end

  test "obtainFloor 400 invalid userid" do
    {status_code, state} = FM.obtainFloor("group1", 5, nil)
    assert status_code == 400
    assert state == %{"message" => "Invalid request: userId must be a string"} 
  end

  test "obtainFloor 400 invalid priority" do
    {status_code, state} = FM.obtainFloor("group1", "user1", "1")
    assert status_code == 400
    assert state == %{"message" => "Invalid request: priority must be a positive integer"} 
  end

  test "obtainFloor 409" do
    {status_code, state} = FM.obtainFloor("group1", "user1", nil)
    assert status_code == 200
    assert state == %{"message" => "Floor obtained by user1 for group group1"}

    {status_code, state} = FM.obtainFloor("group1", "user2", nil)
    assert status_code == 409
    assert state == %{"message" => "Floor is currently held by user1 for group group1"}
  end

  test "obtainFloor 200 priority" do
    {status_code, state} = FM.obtainFloor("group1", "user1", 1)
    assert status_code == 200
    assert state == %{"message" => "Floor obtained by user1 for group group1"}

    {status_code, state} = FM.obtainFloor("group1", "user2", 2)
    assert status_code == 200
    assert state == %{"message" => "Floor obtained by user2 for group group1"}
  end

  test "obtainFloor 409 priority" do
    {status_code, state} = FM.obtainFloor("group1", "user1", 2)
    assert status_code == 200
    assert state == %{"message" => "Floor obtained by user1 for group group1"}

    {status_code, state} = FM.obtainFloor("group1", "user2", 1)
    assert status_code == 409
    assert state == %{"message" => "Floor is currently held by user1 for group group1"}
  end

  test "releaseFloor 200" do
    {status_code, state} = FM.obtainFloor("group1", "user1", nil)
    assert status_code == 200
    assert state == %{"message" => "Floor obtained by user1 for group group1"}

    {status_code, state} = FM.releaseFloor("group1", "user1")
    assert status_code == 200
    assert state == %{"message" => "Floor released by user1 for group group1"}
  end

  test "releaseFloor 403" do
    {status_code, state} = FM.obtainFloor("group1", "user1", nil)
    assert status_code == 200
    assert state == %{"message" => "Floor obtained by user1 for group group1"}

    {status_code, state} = FM.releaseFloor("group1", "user2")
    assert status_code == 403
    assert state == %{"message" => "User user2 does not hold the floor for group group1"}
  end

  test "releaseFloor 403 not acquired" do
    {status_code, state} = FM.releaseFloor("group1", "user2")
    assert status_code == 403
    assert state == %{"message" => "User user2 does not hold the floor for group group1"}
  end


end
