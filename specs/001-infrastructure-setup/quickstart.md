# Quickstart Guide: Stitches Development Environment

**Last Updated**: 2026-01-31  
**Estimated Setup Time**: 10-15 minutes

This guide walks you through setting up the Stitches development environment on your local machine for the first time.

---

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

| Software | Minimum Version | Download Link | Verification Command |
|----------|----------------|---------------|----------------------|
| **Git** | 2.30+ | [git-scm.com](https://git-scm.com) | `git --version` |
| **Node.js** | 20.0+ | [nodejs.org](https://nodejs.org) | `node --version` |
| **npm** | 10.0+ | (included with Node.js) | `npm --version` |
| **.NET SDK** | 10.0+ | [dotnet.microsoft.com](https://dotnet.microsoft.com/download) | `dotnet --version` |
| **Azure CLI** | 2.50+ | [docs.microsoft.com/cli/azure](https://docs.microsoft.com/cli/azure/install-azure-cli) | `az --version` |

### Optional (but Recommended)

- **Visual Studio Code** with extensions:
  - C# Dev Kit
  - ESLint
  - Prettier
  - Azure Tools
- **SQL Server Management Studio** (Windows) or **Azure Data Studio** (all platforms) for database browsing
- **Postman** or **Thunder Client** for API testing

---

## Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/aaronolds/stitches.git

# Navigate to the project directory
cd stitches

# Verify you're on the main branch
git branch --show-current
```

**Expected Output**: `main`

---

## Step 2: Frontend Setup

### Install Dependencies

```bash
# Navigate to the frontend directory
cd frontend

# Install npm packages (this may take 2-3 minutes)
npm install
```

**Expected Output**: `added XXX packages` with no errors

### Configure Environment Variables

```bash
# Copy the environment template
cp .env.example .env.local

# Edit .env.local with your preferred editor
# Example: code .env.local
```

**Required Variables** (`.env.local`):
```bash
VITE_API_URL=http://localhost:5000
```

### Start the Development Server

```bash
# Start the frontend development server
npm run dev
```

**Expected Output**:
```
VITE v5.x.x  ready in XXX ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  press h to show help
```

### Verify Frontend

1. Open your browser to [http://localhost:5173](http://localhost:5173)
2. You should see the React welcome page with no console errors
3. Open browser DevTools (F12) → Console → Verify no errors
4. Make a small change to `src/App.tsx` and save
5. The browser should update within 1 second (HMR working)

**Troubleshooting**:
- **Port 5173 already in use**: Kill the process using port 5173 or change the port in `vite.config.ts`
- **Module not found**: Run `npm install` again
- **TypeScript errors**: Run `npm run type-check` to see detailed errors

---

## Step 3: Backend Setup

### Install Dependencies

Open a new terminal (keep the frontend running) and navigate to the backend directory:

```bash
# From the repository root
cd backend

# Restore NuGet packages
dotnet restore
```

**Expected Output**: `Restore completed in XXX ms`

### Configure Database

#### Option A: SQL Server LocalDB (Windows Only)

LocalDB is automatically included with .NET SDK on Windows. No additional setup required.

**Connection String** (in `appsettings.Development.json`):
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=Stitches;Trusted_Connection=True;MultipleActiveResultSets=true"
  }
}
```

#### Option B: Azure SQL Database Emulator (All Platforms)

If you're on macOS/Linux, use Docker to run SQL Server:

```bash
# Pull SQL Server 2022 image
docker pull mcr.microsoft.com/mssql/server:2022-latest

# Run SQL Server container
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStrong@Passw0rd" \
  -p 1433:1433 --name stitches-sql \
  -d mcr.microsoft.com/mssql/server:2022-latest
```

**Connection String** (in `appsettings.Development.json`):
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost,1433;Database=Stitches;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True"
  }
}
```

### Configure User Secrets

To avoid committing sensitive data, use .NET User Secrets:

```bash
# Initialize user secrets (from backend directory)
cd src/Api
dotnet user-secrets init

# Set connection string (pick one from above)
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=(localdb)\\mssqllocaldb;Database=Stitches;Trusted_Connection=True"

# Verify secrets
dotnet user-secrets list
```

### Apply Database Migrations

```bash
# From backend/src/Api directory
dotnet ef database update --project ../Infrastructure
```

**Expected Output**:
```
Build started...
Build succeeded.
Applying migration '20260131_InitialCreate'.
Done.
```

### Start the API Server

```bash
# From backend directory
dotnet run --project src/Api
```

**Expected Output**:
```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://localhost:5000
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
```

### Verify Backend

1. Open your browser to [http://localhost:5000/swagger](http://localhost:5000/swagger)
2. You should see the Swagger UI with at least the `/api/health` endpoint
3. Click "Try it out" on the health endpoint → "Execute"
4. Response should be `200 OK` with body:
   ```json
   {
     "status": "healthy",
     "timestamp": "2026-01-31T20:30:00.000Z"
   }
   ```

**Troubleshooting**:
- **Port 5000 already in use**: Change port in `src/Api/Properties/launchSettings.json`
- **Database connection failed**: Verify SQL Server is running and connection string is correct
- **Migration failed**: Check that .NET SDK and EF Core tools are installed (`dotnet tool list -g`)
- **401 Unauthorized on endpoints**: Some endpoints may require authentication (Feature 1), health check should work without auth

---

## Step 4: Run Tests

### Frontend Tests

```bash
# From frontend directory
npm test
```

**Expected Output**: All tests pass with coverage report

### Backend Tests

```bash
# From backend directory
dotnet test
```

**Expected Output**:
```
Passed!  - Failed:     0, Passed:     X, Skipped:     0, Total:     X
```

---

## Step 5: Verify Full Integration

### Test Frontend → Backend Communication

1. Ensure both frontend (`:5173`) and backend (`:5000`) are running
2. In the frontend browser console, run:
   ```javascript
   fetch('http://localhost:5000/api/health')
     .then(res => res.json())
     .then(data => console.log(data))
   ```
3. You should see the health response logged in the console

**Troubleshooting**:
- **CORS error**: Verify backend has CORS configured in `Program.cs` to allow `http://localhost:5173`
- **Network error**: Check that backend is running on port 5000

---

## Common Issues & Solutions

### Issue: `npm install` fails with permission errors

**Solution**:
```bash
# Fix npm permissions (macOS/Linux)
sudo chown -R $(whoami) ~/.npm

# Or use nvm to manage Node.js versions
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 20
nvm use 20
```

---

### Issue: `dotnet ef` command not found

**Solution**:
```bash
# Install EF Core tools globally
dotnet tool install --global dotnet-ef

# Verify installation
dotnet ef --version
```

---

### Issue: SQL Server connection timeout

**Solution**:
- **Windows**: Start "SQL Server (MSSQLLOCALDB)" service in Services app
- **Docker**: Verify container is running: `docker ps | grep stitches-sql`
- **Firewall**: Ensure port 1433 is not blocked

---

### Issue: Frontend shows blank page

**Solution**:
1. Check browser console for errors (F12)
2. Verify `VITE_API_URL` in `.env.local` is correct
3. Clear browser cache (Ctrl+Shift+Delete)
4. Restart Vite dev server (`npm run dev`)

---

## Next Steps

Once your environment is set up:

1. **Read the documentation**:
   - [BRD](../docs/BRD.md) - Business requirements
   - [PRD](../docs/PRD.md) - Product requirements
   - [SDD](../docs/SDD.md) - Software design
   - [Constitution](../.specify/memory/constitution.md) - Project governance

2. **Explore the codebase**:
   - Frontend: Start with `frontend/src/App.tsx`
   - Backend: Start with `backend/src/Api/Program.cs`
   - Database: Run `dotnet ef migrations list` to see available migrations

3. **Make your first change**:
   - Find an open issue in GitHub
   - Create a feature branch: `git checkout -b feature/your-feature-name`
   - Make changes, write tests, commit
   - Push and open a pull request

4. **Join the team communication**:
   - Ask questions in Slack channel (if available)
   - Attend daily standup or weekly sync meetings

---

## Development Workflow

### Daily Development Cycle

```bash
# 1. Start frontend (Terminal 1)
cd frontend && npm run dev

# 2. Start backend (Terminal 2)
cd backend && dotnet run --project src/Api

# 3. Make changes to code

# 4. Frontend auto-reloads (HMR)
# 5. Backend requires restart (Ctrl+C, then `dotnet run` again)

# 6. Run tests before committing
npm test          # Frontend
dotnet test       # Backend

# 7. Commit changes
git add .
git commit -m "feat: your feature description"
```

### Adding a New Database Migration

```bash
# From backend directory
dotnet ef migrations add YourMigrationName --project src/Infrastructure

# Review generated migration in src/Infrastructure/Data/Migrations/

# Apply migration
dotnet ef database update --project src/Infrastructure
```

---

## Performance Targets (Local Dev)

As you develop, keep these performance targets in mind:

- ✅ Frontend HMR: < 1 second
- ✅ Backend health check: < 50 ms
- ✅ Frontend page load: < 2 seconds
- ✅ Backend test suite: < 30 seconds
- ✅ Frontend test suite: < 10 seconds

Run `npm run dev -- --debug` in frontend to see detailed performance metrics.

---

## Getting Help

- **Documentation**: Check `README.md` in frontend/ and backend/ directories
- **Issues**: Search [GitHub Issues](https://github.com/aaronolds/stitches/issues) for similar problems
- **Team Chat**: Ask in the dev team Slack/Discord channel
- **Code Review**: Tag @aaronolds for questions on architecture decisions

---

**Welcome to the Stitches team! Happy coding! 🎨**
