defmodule RouterTest do
  use ExUnit.Case
  import Plug.Test
  import Plug.Conn

  doctest Router

  setup do
    FM.reset_state()
    :ok
  end

  def assert_resp_header_is_json(res) do
    assert get_resp_header(res, "content-type") == ["application/json"]
  end
  
  test "acquire floor 200" do
    res = conn(:post, "/groups/group1/floor", %{"userId" => "user1"})
    |> put_req_header("content-type", "application/json")
    |> Router.call(nil) 

    assert_resp_header_is_json(res)
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "Floor obtained by user1 for group group1"}
  end

  test "acquire floor 200 no initial prio" do
    res = conn(:post, "/groups/group1/floor", %{"userId" => "user1"})
    |> put_req_header("content-type", "application/json")
    |> Router.call(nil) 

    assert_resp_header_is_json(res)
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "Floor obtained by user1 for group group1"}

    res = conn(:post, "/groups/group1/floor", %{"userId" => "user2", "priority" => 2})
    |> put_req_header("content-type", "application/json")
    |> Router.call(nil)

    assert_resp_header_is_json(res)
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "Floor obtained by user2 for group group1"}
  end


  test "acquire floor 200 initial prio" do
    res = conn(:post, "/groups/group1/floor", %{"userId" => "user1", "priority" => 3})
    |> put_req_header("content-type", "application/json")
    |> Router.call(nil) 

    assert_resp_header_is_json(res)
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "Floor obtained by user1 for group group1"}

    res = conn(:post, "/groups/group1/floor", %{"userId" => "user2", "priority" => 100})
    |> put_req_header("content-type", "application/json")
    |> Router.call(nil)

    assert_resp_header_is_json(res)
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "Floor obtained by user2 for group group1"}
  end


  test "acquire floor 409 priority too low" do
    res = conn(:post, "/groups/group1/floor", %{"userId" => "user1", "priority" => 3})
    |> put_req_header("content-type", "application/json")
    |> Router.call(nil) 

    assert_resp_header_is_json(res)
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "Floor obtained by user1 for group group1"}

    res = conn(:post, "/groups/group1/floor", %{"userId" => "user2"})
    |> put_req_header("content-type", "application/json")
    |> Router.call(nil)

    assert_resp_header_is_json(res)
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "Floor is currently held by user1 for group group1"}
  end


  test "acquire floor 400 invalid" do
    res = conn(:post, "/groups/group1/floor/", %{"userId" => 0})
    |> put_req_header("content-type", "application/json")
    |> Router.call(nil)
    
    assert_resp_header_is_json(res)
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "Invalid request: userId must be a string"}
  end

  test "acquire floor 400 missing" do
    res = conn(:post, "/groups/group1/floor/")
    |> put_req_header("content-type", "application/json")
    |> Router.call(nil)

    assert_resp_header_is_json(res)
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "Invalid request: userId is required"}
  end

  test "acquire floor 400 negative priority" do
    res = conn(:post, "/groups/group1/floor/", %{"userId" => "user1", "priority" => -1})
    |> put_req_header("content-type", "application/json")
    |> Router.call(nil)

    assert_resp_header_is_json(res)
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "Invalid request: priority must be a positive integer"}
  end

  

  test "acquire floor 409" do
    res = conn(:post, "/groups/group1/floor/", %{"userId" => "first_user"})
    |> put_req_header("content-type", "application/json")
    |> Router.call(nil)

    assert res.status == 200
    assert_resp_header_is_json(res)
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "Floor obtained by first_user for group group1"}

    res = conn(:post, "/groups/group1/floor/", %{"userId" => "second_user"})
    |> put_req_header("content-type", "application/json")
    |> Router.call(nil)

    assert res.status == 409
    assert_resp_header_is_json(res)
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "Floor is currently held by first_user for group group1"}
  end

  test "release floor 200" do
    res = conn(:post, "/groups/group1/floor", %{"userId" => "user1"})
    |> put_req_header("content-type", "application/json")
    |> Router.call(nil)

    assert_resp_header_is_json(res)
    assert res.status == 200
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "Floor obtained by user1 for group group1"}

    res = conn(:delete, "/groups/group1/floor/user1")
    |> Router.call(nil)

    assert_resp_header_is_json(res)
    assert res.status == 200
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "Floor released by user1 for group group1"}
  end

  test "release floor 403" do
    res = conn(:delete, "/groups/group1/floor/user1")
    |> Router.call(nil)

    assert_resp_header_is_json(res)
    assert res.status == 403
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "User user1 does not hold the floor for group group1"}
  end

  test "get floor holder 200" do
      res = conn(:post, "/groups/group1/floor", %{"userId" => "user1"})
      |> put_req_header("content-type", "application/json")
      |> Router.call(nil)

      assert_resp_header_is_json(res)
      assert res.status == 200
      {:ok, body} = JSON.decode(res.resp_body)
      assert body == %{"message" => "Floor obtained by user1 for group group1"}

      res = conn(:get, "/groups/group1/floor")
      |> Router.call(nil)

      assert_resp_header_is_json(res)
      assert res.status == 200
      {:ok, body} = JSON.decode(res.resp_body)
      assert body == %{"message" => "The floor of group group1 is currently held by user1"}	
  end


  test "get floor holder 200 nil user" do
      res = conn(:get, "/groups/group1/floor")
      |> Router.call(nil)

      assert_resp_header_is_json(res)
      assert res.status == 200
      {:ok, body} = JSON.decode(res.resp_body)
      assert body == %{"message" => "The floor of group group1 is currently held by nil"}	
  end


  test "floor timeout release" do
    res = conn(:post, "/groups/group1/floor", %{"userId" => "user1"})
    |> put_req_header("content-type", "application/json")
    |> Router.call(nil)

    assert_resp_header_is_json(res)
    assert res.status == 200
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "Floor obtained by user1 for group group1"}

    Process.sleep(1000)

    res = conn(:get, "/groups/group1/floor")
    |> Router.call(nil)

    assert_resp_header_is_json(res)
    assert res.status == 200
    {:ok, body} = JSON.decode(res.resp_body)
    assert body == %{"message" => "The floor of group group1 is currently held by nil"}
  end

  # Generic client errors

  # test "unknown_path_404" do
  #   res = conn(:post, "/groups//floor/", %{"userId" => "user1"})
  #   |> put_req_header("content-type", "application/json")
  #   |> Router.call(nil)

  #   assert res.status == 404
  #   {:ok, body} = JSON.decode(res.resp_body)
  #   assert body == %{"message" => "Not Found"}

  # end

  # test "bad_content_type_header 415" do
  #   res = conn(:post, "/groups/group1/floor/", %{"userId" => "user1"})
  #   |> put_req_header("content-type", "invalid_content")
  #   |> Router.call(nil)

  #   assert res.status == 415
  #   {:ok, body} = JSON.decode(res.resp_body)
  #   assert body == %{"message" => "Unsupported Media Type"}
  # end

  # test "acquire_floor_content_not_json" do
  #   res = conn(:post, "/groups/group1/floor/")
  #   |> put_req_header("content-type", "invalid_content")
  #   |> Router.call(nil)

  #   assert res.status == 415
  #   {:ok, body} = JSON.decode(res.resp_body)
  #   assert body == %{"message" => "Unsupported Media Type"}
  # end

end
