# Quickstart Guide: Authentication & Persistence Foundation

**Feature**: 002-auth-persistence  
**Date**: 2026-03-03  
**Prerequisites**: Feature 001 (Infrastructure Setup) must be complete — database provisioned, Azure services running, secrets in Key Vault.

This guide covers additional setup steps needed for the auth and persistence feature on top of the existing dev environment from Feature 001.

---

## Prerequisites (in addition to Feature 001)

### Required Accounts / Services

| Service | Purpose | Setup Link |
|---------|---------|------------|
| **Microsoft Entra External ID** tenant | OAuth identity provider | Azure Portal → Entra ID → Create External Tenant |
| **Google Cloud Console** project | Google OAuth provider | [console.cloud.google.com](https://console.cloud.google.com) |

### Required Configuration

| Item | Description | Where |
|------|-------------|-------|
| Entra External ID Client ID (SPA) | Frontend app registration | Azure Portal → Entra External ID → App Registrations |
| Entra External ID Client ID (API) | Backend API registration | Azure Portal → Entra External ID → App Registrations |
| API Scope | e.g. `api://{api-client-id}/Designs.ReadWrite` | API app registration → Expose an API |
| Google OAuth Client ID/Secret | Social identity provider | Google Cloud Console → APIs & Services → Credentials |
| Tenant subdomain | e.g. `stitchesauth` | Entra External ID tenant properties |

---

## Step 1: Configure Entra External ID

### 1a. Create External Tenant

1. Azure Portal → Microsoft Entra ID → Manage Tenants → + Create
2. Select **Customer** tenant type
3. Set tenant name (e.g., `stitchesauth`) and domain
4. Complete creation

### 1b. Register SPA Application

1. In the external tenant → App Registrations → New Registration
2. Name: `Stitches SPA`
3. Supported account types: **Accounts in this organizational directory only**
4. Redirect URI: `Single-page application (SPA)` → `http://localhost:5173`
5. Copy the **Application (client) ID** — this is `VITE_MSAL_CLIENT_ID`

### 1c. Register API Application

1. App Registrations → New Registration
2. Name: `Stitches API`
3. Expose an API → Set Application ID URI (e.g., `api://{client-id}`)
4. Add scope: `Designs.ReadWrite` (admin consent not required)
5. Copy the **Application (client) ID** — used in backend appsettings

### 1d. Configure Google Social Provider

1. Google Cloud Console → Create OAuth 2.0 client ID
2. Authorized redirect URI: `https://{tenant-subdomain}.ciamlogin.com/{tenant-id}/federation/oauth2`
3. In Entra External ID → Identity Providers → Google → Add Client ID/Secret
4. Create User Flow → Sign up and sign in → Include Google provider

---

## Step 2: Frontend Configuration

### Install new dependencies

```bash
cd frontend
npm install @azure/msal-browser @azure/msal-react
```

### Create environment file

```bash
# Create .env.local (gitignored)
cat > .env.local << 'EOF'
VITE_MSAL_CLIENT_ID=<your-spa-client-id>
VITE_MSAL_AUTHORITY=https://<tenant-subdomain>.ciamlogin.com/<tenant-id>
VITE_API_BASE_URL=http://localhost:5000
VITE_API_SCOPE=api://<api-client-id>/Designs.ReadWrite
EOF
```

### Verify

```bash
npm run dev
# Should start on http://localhost:5173 and show sign-in page
```

---

## Step 3: Backend Configuration

### Install new NuGet packages

```bash
cd backend
dotnet add src/Api/Api.csproj package Microsoft.Identity.Web
dotnet add src/Infrastructure/Infrastructure.csproj package Microsoft.EntityFrameworkCore.SqlServer
dotnet add src/Infrastructure/Infrastructure.csproj package Microsoft.EntityFrameworkCore.Design
dotnet add src/Infrastructure/Infrastructure.csproj package Microsoft.EntityFrameworkCore.Tools
```

### Configure User Secrets (local development)

```bash
cd src/Api
dotnet user-secrets init
dotnet user-secrets set "AzureAd:Instance" "https://<tenant-subdomain>.ciamlogin.com/"
dotnet user-secrets set "AzureAd:TenantId" "<tenant-id>"
dotnet user-secrets set "AzureAd:ClientId" "<api-client-id>"
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=<sql-server>.database.windows.net;Database=stitches-dev;User Id=<user>;Password=<password>;Encrypt=True"
```

### Apply EF Core Migrations

```bash
cd backend
dotnet ef database update --project src/Infrastructure --startup-project src/Api
```

### Verify

```bash
dotnet run --project src/Api
# Health check: curl http://localhost:5000/api/health
# Swagger:     http://localhost:5000/swagger
```

---

## Step 4: Verify End-to-End

1. Start backend: `cd backend && dotnet run --project src/Api`
2. Start frontend: `cd frontend && npm run dev`
3. Open http://localhost:5173
4. Click "Sign in with Google"
5. Complete OAuth flow → should redirect back as authenticated user
6. Create a new design → should appear in design library
7. Edit design → wait 30 seconds → "All changes saved" indicator appears
8. Refresh page → design loads with autosaved state

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| MSAL redirect loop | Ensure SPA redirect URI in Entra matches exactly `http://localhost:5173` |
| 401 on API calls | Verify API scope matches between SPA config and backend `AzureAd:ClientId` |
| EF Core migration fails | Ensure connection string is correct in user secrets. Run `dotnet ef migrations list --project src/Infrastructure --startup-project src/Api` to verify |
| Google sign-in button missing | Confirm Google is added as identity provider in Entra External ID and included in the user flow |
| CORS errors | Verify `http://localhost:5173` is in the allowed origins in Program.cs |

---

## Running Tests

```bash
# Backend unit tests
cd backend && dotnet test

# Frontend unit tests
cd frontend && npm test

# Backend integration tests (requires database)
cd backend && dotnet test --filter "FullyQualifiedName~Integration"
```
