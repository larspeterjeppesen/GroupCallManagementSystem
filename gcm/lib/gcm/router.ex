defmodule Router do
  import Plug.Conn
  # use Plug.ErrorHandler
  use Plug.Router
  
  # TODO: errorhandling
  # https://hexdocs.pm/plug/Plug.Router.html

  # paths = %{"obtainFloor" => "/groups/:groupid/floor/",
            # "releaseFloor" => "/groups/:groupid/floor/:userid/",
            # "getFloorHolder" => "/groups/:groupid/floor/"}
  # paths_list = Map.to_list(paths) |> Enum.map(&(elem(&1, 1)))

  # plug :ensure_path_exists, paths_list
  plug :match
  # plug :ensure_json_content_type

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*"],
    json_decoder: Jason
  
  plug :dispatch
  
  post "/groups/:groupid/floor" do
    userid = conn.body_params["userId"]
    priority = conn.body_params["priority"]
    {status_code, resp_body} = FM.obtainFloor(groupid, userid, priority)
    resp(conn, status_code, JSON.encode_to_iodata!(resp_body))
    |> put_resp_header("content-type", "application/json")
    |> send_resp()
  end

  delete "/groups/:groupid/floor/:userid/" do
    {status_code, resp_body} = FM.releaseFloor("#{groupid}", "#{userid}")
    resp(conn, status_code, JSON.encode_to_iodata!(resp_body))
    |> put_resp_header("content-type", "application/json")
    |> send_resp()
  end

  get "/groups/:groupid/floor/" do
    {status_code, resp_body} = FM.getFloorHolder("#{groupid}")
    resp(conn, status_code, JSON.encode_to_iodata!(resp_body))
    |> put_resp_header("content-type", "application/json")
    |> send_resp()
  end

  # @impl Plug.ErrorHandler
  # def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
  #   IO.inspect _kind
  #   IO.inspect _reason
  #   IO.inspect _stack
  #   send_resp(conn, conn.status, "Unhandled error")
  # end

  # defp ensure_path_exists(conn, valid_paths) do
  #   req_path_words = String.split(conn.request_path, "/")
  #   |> Enum.filter(&(&1 != ""))

  #   # compare requested path with existing paths 
  #   path_is_valid = Enum.map(valid_paths, &(String.split(&1, "/")))
  #   |> Enum.map(fn words -> Enum.filter(words, &(&1 != "")) end)
  #   |> Enum.filter(&(length(&1) == length(req_path_words)))
  #   |> Enum.map(fn words -> #disregard atom parameters when checking if paths are equal
  #                 Enum.zip_reduce(words, req_path_words, true,
  #                                 fn x,y,acc ->
  #                                   ((x==y) || (String.at(x,0) == ":")) && acc
  #                                 end)
  #               end)
  #   |> length() > 0
  
  #   if path_is_valid do
  #     conn
  #   else
  #     send_resp(conn, 404, JSON.encode_to_iodata!(%{"message" => "Not Found"})) |> halt()
  #   end
  # end

  # defp ensure_json_content_type(conn, _opts) do
  #   case Plug.Conn.get_req_header(conn, "content-type") do
  #     ["application/json" <> _tail] -> conn #allow variants since not specified (eg charset=utf-8)
  #     [] -> conn
  #     _ -> send_resp(conn, 415, JSON.encode_to_iodata!(%{"message" => "Unsupported Media Type"})) |> halt()
  #   end
  # end
  
end
 

