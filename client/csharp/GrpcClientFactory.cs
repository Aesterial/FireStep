using Aesterial.FireStep.Api.V1.Login;
using Aesterial.FireStep.Api.V1.Seances;
using Aesterial.FireStep.Api.V1.Session;
using Aesterial.FireStep.Api.V1.User;
using Grpc.Net.Client;
using System.Net.Http;

namespace Aesterial.FireStep.Client.Grpc;

public static class GrpcClientFactory
{
    public const string DefaultServerAddress = FireStepApiConstants.DefaultServerAddress;

    public static GrpcChannel CreateChannel(string? address = null)
    {
        AppContext.SetSwitch("System.Net.Http.SocketsHttpHandler.Http2UnencryptedSupport", true);

        return GrpcChannel.ForAddress(
            ResolveAddress(address),
            new GrpcChannelOptions
            {
                HttpHandler = new SocketsHttpHandler
                {
                    EnableMultipleHttp2Connections = true,
                },
            }
        );
    }

    public static FireStepGrpcClients CreateClients(string? address = null)
    {
        return new FireStepGrpcClients(address);
    }

    public static LoginService.LoginServiceClient CreateLoginClient(string? address = null)
    {
        return new LoginService.LoginServiceClient(CreateChannel(address));
    }

    public static SessionsService.SessionsServiceClient CreateSessionsClient(string? address = null)
    {
        return new SessionsService.SessionsServiceClient(CreateChannel(address));
    }

    public static global::Aesterial.FireStep.Api.V1.Seances.SeancesService.SeancesServiceClient CreateSeancesClient(string? address = null)
    {
        return new global::Aesterial.FireStep.Api.V1.Seances.SeancesService.SeancesServiceClient(CreateChannel(address));
    }

    public static UserService.UserServiceClient CreateUserClient(string? address = null)
    {
        return new UserService.UserServiceClient(CreateChannel(address));
    }

    private static string ResolveAddress(string? address)
    {
        return string.IsNullOrWhiteSpace(address) ? DefaultServerAddress : address;
    }
}
