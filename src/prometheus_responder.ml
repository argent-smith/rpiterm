module Server (CON : Conduit_mirage.S) = struct
  module Server = Cohttp_mirage.Server(Conduit_mirage.Flow)
  module PServer = Prometheus_app.Cohttp(Cohttp_mirage.Server_with_conduit)

  let callback conn req body =
    let path = Uri.path (Cohttp.Request.uri req) in
    Log.info (fun f -> f "Serving request for %s" path)
    >> PServer.callback conn req body

  let spec = Server.make ~callback ()

  let serve_with conduit port =
    CON.listen conduit (`TCP port) (Server.listen spec)
end
