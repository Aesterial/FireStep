using System.Text.Json;
using System.Text.Json.Serialization;
using Aesterial.FireStep.Client.Grpc;
using Grpc.Core;

var jsonOptions = new JsonSerializerOptions
{
    PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    WriteIndented = false,
};

try
{
    if (args.Length == 0)
    {
        throw new InvalidOperationException("No command specified.");
    }

    var command = args[0].Trim().ToLowerInvariant();
    var options = ParseOptions(args.Skip(1).ToArray());
    var server = GetOption(options, "server", FireStepApiConstants.DefaultServerAddress);

    using var client = new FireStepApiClient(server);

    switch (command)
    {
        case "login":
        {
            var auth = await client.LoginAsync(
                RequireOption(options, "username"),
                RequireOption(options, "password")
            ).ConfigureAwait(false);

            WriteSuccess(new
            {
                sessionToken = auth.SessionToken,
                user = auth.User,
            });
            return 0;
        }

        case "register":
        {
            var auth = await client.RegisterAsync(
                RequireOption(options, "username"),
                RequireOption(options, "email"),
                RequireOption(options, "password"),
                RequireOption(options, "initials"),
                RequireOption(options, "org")
            ).ConfigureAwait(false);

            WriteSuccess(new
            {
                sessionToken = auth.SessionToken,
                user = auth.User,
            });
            return 0;
        }

        case "validate":
        {
            var user = await client.ValidateSessionAsync(RequireOption(options, "session-token")).ConfigureAwait(false);
            WriteSuccess(new { user });
            return 0;
        }

        case "save-seance":
        {
            var payloadPath = RequireOption(options, "payload-file");
            var payloadText = await File.ReadAllTextAsync(payloadPath).ConfigureAwait(false);
            var payload = JsonSerializer.Deserialize<FireStepSeancePayload>(payloadText, jsonOptions)
                ?? throw new InvalidOperationException("Failed to deserialize seance payload.");

            var seanceId = await client.SaveSeanceAsync(payload).ConfigureAwait(false);
            WriteSuccess(new { seanceId });
            return 0;
        }

        default:
            throw new InvalidOperationException($"Unknown command: {command}");
    }
}
catch (Exception exception)
{
    var message = exception is RpcException rpcException
        ? FormatRpcException(rpcException)
        : exception.Message;

    Console.WriteLine(JsonSerializer.Serialize(new
    {
        success = false,
        error = message,
    }, jsonOptions));

    return 1;
}

void WriteSuccess(object data)
{
    Console.WriteLine(JsonSerializer.Serialize(new
    {
        success = true,
        data,
    }, jsonOptions));
}

static Dictionary<string, string> ParseOptions(string[] args)
{
    var options = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
    for (var index = 0; index < args.Length; index += 2)
    {
        if (index + 1 >= args.Length)
        {
            throw new InvalidOperationException($"Missing value for option {args[index]}.");
        }

        var key = args[index];
        if (!key.StartsWith("--", StringComparison.Ordinal))
        {
            throw new InvalidOperationException($"Invalid option name: {key}");
        }

        options[key[2..]] = args[index + 1];
    }

    return options;
}

static string RequireOption(IReadOnlyDictionary<string, string> options, string key)
{
    if (!options.TryGetValue(key, out var value) || string.IsNullOrWhiteSpace(value))
    {
        throw new InvalidOperationException($"Missing required option --{key}.");
    }

    return value;
}

static string GetOption(IReadOnlyDictionary<string, string> options, string key, string fallback)
{
    return options.TryGetValue(key, out var value) && !string.IsNullOrWhiteSpace(value)
        ? value
        : fallback;
}

static string FormatRpcException(RpcException exception)
{
    return exception.StatusCode switch
    {
        StatusCode.InvalidArgument => "Backend отклонил запрос: неверные аргументы.",
        StatusCode.AlreadyExists => "Такие учётные данные уже используются.",
        StatusCode.Unauthenticated => "Авторизация не пройдена. Проверьте логин, пароль или сохранённую сессию.",
        StatusCode.Unavailable => "Backend недоступен по указанному адресу.",
        _ => string.IsNullOrWhiteSpace(exception.Status.Detail)
            ? $"gRPC error: {exception.StatusCode}"
            : exception.Status.Detail,
    };
}
