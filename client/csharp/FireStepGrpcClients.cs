using Aesterial.FireStep.Api.V1.Login;
using Aesterial.FireStep.Api.V1.Seances;
using Aesterial.FireStep.Api.V1.Session;
using Aesterial.FireStep.Api.V1.User;
using Grpc.Net.Client;

namespace Aesterial.FireStep.Client.Grpc;

public sealed class FireStepGrpcClients : IDisposable
{
    public FireStepGrpcClients(string? address = null)
    {
        Channel = GrpcClientFactory.CreateChannel(address);
        Login = new LoginService.LoginServiceClient(Channel);
        Seances = new global::Aesterial.FireStep.Api.V1.Seances.SeancesService.SeancesServiceClient(Channel);
        Sessions = new SessionsService.SessionsServiceClient(Channel);
        User = new UserService.UserServiceClient(Channel);
    }

    public GrpcChannel Channel { get; }

    public LoginService.LoginServiceClient Login { get; }

    public global::Aesterial.FireStep.Api.V1.Seances.SeancesService.SeancesServiceClient Seances { get; }

    public SessionsService.SessionsServiceClient Sessions { get; }

    public UserService.UserServiceClient User { get; }

    public void Dispose()
    {
        Channel.Dispose();
    }
}
