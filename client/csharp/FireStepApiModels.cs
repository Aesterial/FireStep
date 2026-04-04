namespace Aesterial.FireStep.Client.Grpc;

public sealed class FireStepUserInfo
{
    public string Id { get; set; } = string.Empty;

    public string Username { get; set; } = string.Empty;

    public string Initials { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string Org { get; set; } = string.Empty;

    public long JoinedAtUnixMs { get; set; }
}

public sealed class FireStepAuthState
{
    public string SessionToken { get; set; } = string.Empty;

    public FireStepUserInfo User { get; set; } = new();
}

public sealed class FireStepActionRecord
{
    public int Id { get; set; }

    public string Action { get; set; } = string.Empty;

    public long AtUnixMs { get; set; }
}

public sealed class FireStepSeancePayload
{
    public string SessionToken { get; set; } = string.Empty;

    public int Errors { get; set; }

    public long StartedAtUnixMs { get; set; }

    public long DoneAtUnixMs { get; set; }

    public List<FireStepActionRecord> Actions { get; set; } = [];
}
