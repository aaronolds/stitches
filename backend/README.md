# Stitches Backend

ASP.NET Core 10+ Web API for the Stitches application.

## Prerequisites

- **.NET SDK**: 10.0+ (check with `dotnet --version`)
- **SQL Server LocalDB** (Windows) or **Docker** (macOS/Linux) for local database
- **Azure CLI**: 2.50+ (for Key Vault integration in production)

## Setup

```bash
# Navigate to backend directory
cd backend

# Restore NuGet packages
dotnet restore

# Apply database migrations (optional - if database exists)
dotnet ef database update --project src/Infrastructure --startup-project src/Api

# Start the API server
dotnet run --project src/Api
```

Open [http://localhost:5000/swagger](http://localhost:5000/swagger) to view API documentation.

## Available Commands

| Command | Description |
|---------|-------------|
| `dotnet restore` | Restore NuGet packages |
| `dotnet build` | Build the solution |
| `dotnet run --project src/Api` | Start the API server |
| `dotnet test` | Run all tests |
| `dotnet ef database update` | Apply database migrations |
| `dotnet ef migrations add <Name>` | Create a new migration |

## Project Structure

```text
src/
├── Api/                    # HTTP layer (Controllers, Program.cs)
│   └── Controllers/        # API endpoints
├── Application/            # Business logic, use cases
├── Domain/                 # Entities, value objects
└── Infrastructure/         # Data access, external services
    └── Data/               # EF Core DbContext, migrations

tests/
├── Api.Tests/              # Controller/endpoint tests
├── Application.Tests/      # Business logic unit tests
├── Domain.Tests/           # Domain model tests
└── Integration.Tests/      # End-to-end API tests
```

## Configuration

### Local Development

Configuration files:

- `appsettings.json` - Shared defaults
- `appsettings.Development.json` - Local development settings

### User Secrets (Recommended for Local Dev)

Use .NET User Secrets to avoid committing sensitive data:

```bash
# Initialize user secrets
cd src/Api
dotnet user-secrets init

# Set connection string
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=(localdb)\\mssqllocaldb;Database=Stitches;Trusted_Connection=True"

# List secrets
dotnet user-secrets list
```

### Database Setup

#### Option A: SQL Server LocalDB (Windows)

LocalDB is included with .NET SDK on Windows. No additional setup required.

#### Option B: Docker (macOS/Linux)

```bash
# Pull SQL Server image
docker pull mcr.microsoft.com/mssql/server:2022-latest

# Run SQL Server container
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStrong@Passw0rd" \
  -p 1433:1433 --name stitches-sql \
  -d mcr.microsoft.com/mssql/server:2022-latest
```

Update connection string in user secrets:

```bash
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=localhost,1433;Database=Stitches;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True"
```

## Testing

Uses [xUnit](https://xunit.net/) with [NSubstitute](https://nsubstitute.github.io/) for mocking and [FluentAssertions](https://fluentassertions.com/) for assertions.

```bash
# Run all tests
dotnet test

# Run tests with coverage
dotnet test --collect:"XPlat Code Coverage"

# Run specific test project
dotnet test tests/Api.Tests
```

### Test Patterns

Follow AAA (Arrange, Act, Assert) pattern:

```csharp
[Fact]
public async Task GetHealth_ReturnsOk()
{
    // Arrange
    var controller = new HealthController();

    // Act
    var result = await controller.Get();

    // Assert
    result.Should().BeOfType<OkObjectResult>();
}
```

## API Endpoints

### Health Check

```http
GET /api/health
```

**Response**: `200 OK`

```json
{
  "status": "healthy",
  "timestamp": "2026-01-31T12:00:00.000Z"
}
```

### Swagger Documentation

Available in Development environment at `/swagger`.

## Troubleshooting

### Database connection failed

1. Verify SQL Server is running
2. Check connection string in User Secrets
3. For Docker: `docker ps | grep stitches-sql`

### EF Core tools not found

```bash
dotnet tool install --global dotnet-ef
```

### Port 5000 already in use

Update port in `Properties/launchSettings.json`:

```json
{
  "profiles": {
    "Api": {
      "applicationUrl": "http://localhost:5001"
    }
  }
}
```

---

**Last Updated**: 2026-01-31
