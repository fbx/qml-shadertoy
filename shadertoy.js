.pragma library
.import fbx.web 1.0 as Web

var apiUrl = "https://www.shadertoy.com/api/v1";
var mediaUrl = "https://www.shadertoy.com";
var apiKey = "XXXX";

function createClient()
{
    var c = new Web.Rest.Client(apiUrl, {
        suffix: "",
        http_transaction_factory: Web.Http.Transaction.factory,
    });
    c.add("shaders");
    c.shaders.add("query");
    return c;
}
