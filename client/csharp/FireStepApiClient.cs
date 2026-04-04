using Aesterial.FireStep.Api.V1.Login;
using Aesterial.FireStep.Api.V1.Seances;
using Aesterial.FireStep.Api.V1.User;
using Google.Protobuf.WellKnownTypes;
using Grpc.Core;

namespace Aesterial.FireStep.Client.Grpc;

public sealed class FireStepApiClient : IDisposable
{
    private readonly FireStepGrpcClients _clients;

    public FireStepApiClient(string? address = null)
    {
        _clients = GrpcClientFactory.CreateClients(address);
    }

    public async Task<FireStepAuthState> LoginAsync(string username, string password, CancellationToken cancellationToken = default)
    {
        var headers = CreateDeviceHeaders();
        using var call = _clients.Login.LoginAsync(
            new LoginRequest
            {
                Username = username?.Trim() ?? string.Empty,
                Password = password ?? string.Empty,
            },
            headers: headers,
            cancellationToken: cancellationToken
        );

        var user = await call.ResponseAsync.ConfigureAwait(false);
        var responseHeaders = await call.ResponseHeadersAsync.ConfigureAwait(false);
        return new FireStepAuthState
        {
            SessionToken = ExtractSessionToken(responseHeaders),
            User = MapUser(user),
        };
    }

    public async Task<FireStepAuthState> RegisterAsync(
        string username,
        string email,
        string password,
        string initials,
        string org,
        CancellationToken cancellationToken = default
    )
    {
        var headers = CreateDeviceHeaders();
        using var call = _clients.Login.RegisterAsync(
            new RegisterRequest
            {
                Username = username?.Trim() ?? string.Empty,
                Email = email?.Trim() ?? string.Empty,
                Password = password ?? string.Empty,
                Initials = initials?.Trim() ?? string.Empty,
                Org = org?.Trim() ?? string.Empty,
            },
            headers: headers,
            cancellationToken: cancellationToken
        );

        var user = await call.ResponseAsync.ConfigureAwait(false);
        var responseHeaders = await call.ResponseHeadersAsync.ConfigureAwait(false);
        return new FireStepAuthState
        {
            SessionToken = ExtractSessionToken(responseHeaders),
            User = MapUser(user),
        };
    }

    public async Task<FireStepUserInfo> ValidateSessionAsync(string sessionToken, CancellationToken cancellationToken = default)
    {
        var user = await _clients.User.InfoAsync(
            new Empty(),
            headers: CreateAuthHeaders(sessionToken),
            cancellationToken: cancellationToken
        ).ResponseAsync.ConfigureAwait(false);

        return MapUser(user);
    }

    public async Task<string> SaveSeanceAsync(FireStepSeancePayload payload, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(payload);

        var request = new CreateSeanceRequest
        {
            Errors = payload.Errors,
            At = Timestamp.FromDateTimeOffset(FromUnixMilliseconds(payload.StartedAtUnixMs)),
            Done = Timestamp.FromDateTimeOffset(FromUnixMilliseconds(payload.DoneAtUnixMs)),
        };

        foreach (var action in payload.Actions)
        {
            request.Actions.Add(new Aesterial.FireStep.Api.V1.Seances.Action
            {
                Id = action.Id,
                Action_ = action.Action ?? string.Empty,
                At = Timestamp.FromDateTimeOffset(FromUnixMilliseconds(action.AtUnixMs)),
            });
        }

        var response = await _clients.Seances.CreateAsync(
            request,
            headers: CreateAuthHeaders(payload.SessionToken),
            cancellationToken: cancellationToken
        ).ResponseAsync.ConfigureAwait(false);

        return response.Id;
    }

    public void Dispose()
    {
        _clients.Dispose();
    }

    private static Metadata CreateDeviceHeaders()
    {
        return new Metadata
        {
            { FireStepApiConstants.DeviceHeaderName, FireStepApiConstants.ClientDeviceName },
        };
    }

    private static Metadata CreateAuthHeaders(string sessionToken)
    {
        if (string.IsNullOrWhiteSpace(sessionToken))
        {
            throw new InvalidOperationException("Session token is empty.");
        }

        var headers = CreateDeviceHeaders();
        headers.Add(FireStepApiConstants.SessionHeaderName, sessionToken.Trim());
        return headers;
    }

    private static string ExtractSessionToken(Metadata headers)
    {
        var entry = headers.FirstOrDefault(static h => string.Equals(h.Key, FireStepApiConstants.SessionHeaderName, StringComparison.OrdinalIgnoreCase));
        if (entry == null || string.IsNullOrWhiteSpace(entry.Value))
        {
            throw new InvalidOperationException("Backend returned no session header.");
        }

        return entry.Value;
    }

    private static FireStepUserInfo MapUser(User user)
    {
        return new FireStepUserInfo
        {
            Id = user.Id,
            Username = user.Username,
            Initials = user.Initials,
            Email = user.Email,
            Org = user.Org,
            JoinedAtUnixMs = user.Joined?.ToDateTimeOffset().ToUnixTimeMilliseconds() ?? 0L,
        };
    }

    private static DateTimeOffset FromUnixMilliseconds(long unixMilliseconds)
    {
        if (unixMilliseconds <= 0)
        {
            throw new InvalidOperationException("Unix timestamp must be greater than zero.");
        }

        return DateTimeOffset.FromUnixTimeMilliseconds(unixMilliseconds);
    }
}
