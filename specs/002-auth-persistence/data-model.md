# Data Model Design: Authentication & Persistence Foundation

**Feature**: 002-auth-persistence  
**Date**: 2026-03-03  
**Purpose**: Define entities, relationships, validation rules, and indexes for user accounts and design persistence

---

## Entity: User

**Purpose**: Represents an authenticated individual who owns designs. Created automatically on first OAuth sign-in.

### Properties

| Property | Type | Description | Constraints |
|----------|------|-------------|-------------|
| `Id` | Guid | Unique user identifier | PK. Generated server-side (UUIDv7 for time-ordered inserts) |
| `Email` | string? | Email from OAuth profile | Optional (some providers may not return it). Max 320 chars |
| `DisplayName` | string | Display name from OAuth profile | Required. Max 200 chars |
| `OAuthProvider` | string | Identity provider name | Required. One of: "google", "facebook", "apple", "microsoft" |
| `OAuthProviderId` | string | Provider-specific user identifier | Required. Max 256 chars. Unique per provider |
| `CreatedAt` | DateTimeOffset | Account creation timestamp | Required. Set once on creation. UTC |

### Validation Rules

- `OAuthProvider` + `OAuthProviderId` must be unique (composite unique index)
- `DisplayName` must be non-empty and ≤200 characters
- `Email`, if provided, must be a valid email format and ≤320 characters
- `CreatedAt` is immutable after creation

### Indexes

| Name | Columns | Type | Purpose |
|------|---------|------|---------|
| `PK_Users` | `Id` | Primary Key, Clustered | Row identity |
| `IX_Users_Provider` | `OAuthProvider, OAuthProviderId` | Unique, Nonclustered | Prevent duplicate accounts per provider; fast lookup on sign-in |
| `IX_Users_Email` | `Email` | Nonclustered | Lookup by email (admin/support scenarios) |

### Relationships

- **Has Many** `Design`: A user owns zero or more designs

### EF Core Configuration

```csharp
builder.HasKey(u => u.Id);
builder.Property(u => u.DisplayName).IsRequired().HasMaxLength(200);
builder.Property(u => u.Email).HasMaxLength(320);
builder.Property(u => u.OAuthProvider).IsRequired().HasMaxLength(50);
builder.Property(u => u.OAuthProviderId).IsRequired().HasMaxLength(256);
builder.HasIndex(u => new { u.OAuthProvider, u.OAuthProviderId }).IsUnique();
builder.HasIndex(u => u.Email);
```

### Example

```json
{
  "id": "019503a1-b2c3-7d4e-8f5a-6b7c8d9e0f12",
  "email": "jane.doe@gmail.com",
  "displayName": "Jane Doe",
  "oAuthProvider": "google",
  "oAuthProviderId": "104234876547382916542",
  "createdAt": "2026-03-15T14:30:00+00:00"
}
```

---

## Entity: Design

**Purpose**: Represents a cross-stitch pattern created and owned by a user. Supports soft-delete with 30-day recovery.

### Properties

| Property | Type | Description | Constraints |
|----------|------|-------------|-------------|
| `Id` | Guid | Unique design identifier | PK. Generated server-side (UUIDv7) |
| `UserId` | Guid | Owner user identifier | Required. FK → User.Id |
| `Title` | string | Design title | Required. 1–255 chars. Default: "Untitled Design" |
| `Width` | int | Grid width in stitches | Required. 1–1000 |
| `Height` | int | Grid height in stitches | Required. 1–1000 |
| `StitchData` | string | Grid of colour/symbol assignments | Required. JSON string. Max ~16MB (nvarchar(max)) |
| `Palette` | string | Colour palette definition | Required. JSON string |
| `SymbolMap` | string | Symbol-to-colour mapping | Required. JSON string |
| `UploadedImageUrl` | string? | Reference to uploaded source image | Optional. Azure Blob Storage URL. Max 2048 chars |
| `CreatedAt` | DateTimeOffset | Design creation timestamp | Required. Set once on creation. UTC |
| `UpdatedAt` | DateTimeOffset | Last modification timestamp | Required. Updated on every save (autosave or manual). UTC |
| `IsDeleted` | bool | Soft-delete flag | Required. Default: false |
| `DeletedAt` | DateTimeOffset? | Deletion timestamp | Null when active. Set when soft-deleted. Drives 30-day purge |

### State Transitions

```
ACTIVE (IsDeleted=false, DeletedAt=null)
  → SOFT_DELETED (IsDeleted=true, DeletedAt=<now>)    — user deletes design
  → ACTIVE (update Title, StitchData, etc.)            — user edits design

SOFT_DELETED
  → ACTIVE (IsDeleted=false, DeletedAt=null)           — user restores within 30 days
  → PURGED (row deleted permanently)                   — background job after 30 days
```

### Validation Rules

- `Title` must be 1–255 characters (FR-016a)
- `Width` must be 1–1000 (FR-016a)
- `Height` must be 1–1000 (FR-016a)
- `StitchData`, `Palette`, `SymbolMap` must be valid JSON
- `UserId` must reference an existing User
- `DeletedAt` is set only when `IsDeleted` transitions to true
- `UpdatedAt` must be ≥ `CreatedAt`

### Indexes

| Name | Columns | Type | Purpose |
|------|---------|------|---------|
| `PK_Designs` | `Id` | Primary Key, Clustered | Row identity |
| `IX_Designs_UserActive` | `UserId, IsDeleted, UpdatedAt DESC` | Nonclustered, Filtered (IsDeleted=0) | List user's active designs sorted by last modified |
| `IX_Designs_UserDeleted` | `UserId, IsDeleted, DeletedAt DESC` | Nonclustered, Filtered (IsDeleted=1) | "Recently Deleted" view — user's soft-deleted designs |
| `IX_Designs_UserTitle` | `UserId, IsDeleted, Title` | Nonclustered | Title search within a user's library |
| `IX_Designs_Purge` | `IsDeleted, DeletedAt` | Nonclustered, Filtered (IsDeleted=1) | Background purge job — find expired soft-deletes |

### Relationships

- **Belongs To** `User`: Each design has exactly one owner (UserId → User.Id)
- Cascade behavior: if a User is deleted, their Designs are cascade-deleted (unlikely in normal operation since user deletion is out of scope)

### Global Query Filter

```csharp
// Excludes soft-deleted designs from all normal queries
builder.HasQueryFilter(d => !d.IsDeleted);
```

Use `IgnoreQueryFilters()` for:
- "Recently Deleted" view (show soft-deleted designs within 30 days)
- Background purge job (find designs where `DeletedAt` < 30 days ago)

### EF Core Configuration

```csharp
builder.HasKey(d => d.Id);
builder.Property(d => d.Title).IsRequired().HasMaxLength(255).HasDefaultValue("Untitled Design");
builder.Property(d => d.Width).IsRequired();
builder.Property(d => d.Height).IsRequired();
builder.Property(d => d.StitchData).IsRequired().HasColumnType("nvarchar(max)");
builder.Property(d => d.Palette).IsRequired().HasColumnType("nvarchar(max)");
builder.Property(d => d.SymbolMap).IsRequired().HasColumnType("nvarchar(max)");
builder.Property(d => d.UploadedImageUrl).HasMaxLength(2048);
builder.Property(d => d.IsDeleted).HasDefaultValue(false);

builder.HasOne<User>().WithMany().HasForeignKey(d => d.UserId).OnDelete(DeleteBehavior.Cascade);
builder.HasQueryFilter(d => !d.IsDeleted);

builder.HasIndex(d => new { d.UserId, d.IsDeleted, d.UpdatedAt })
       .HasDatabaseName("IX_Designs_UserActive")
       .HasFilter("[IsDeleted] = 0")
       .IsDescending(false, false, true);

builder.HasIndex(d => new { d.UserId, d.IsDeleted, d.DeletedAt })
       .HasDatabaseName("IX_Designs_UserDeleted")
       .HasFilter("[IsDeleted] = 1")
       .IsDescending(false, false, true);

builder.HasIndex(d => new { d.UserId, d.IsDeleted, d.Title })
       .HasDatabaseName("IX_Designs_UserTitle");

builder.HasIndex(d => new { d.IsDeleted, d.DeletedAt })
       .HasDatabaseName("IX_Designs_Purge")
       .HasFilter("[IsDeleted] = 1");
```

### Example (Active Design)

```json
{
  "id": "019503b2-c3d4-7e5f-9a6b-7c8d9e0f1234",
  "userId": "019503a1-b2c3-7d4e-8f5a-6b7c8d9e0f12",
  "title": "My First Cross-Stitch",
  "width": 100,
  "height": 80,
  "stitchData": "{\"grid\":[[\"#FF0000\",\"#00FF00\",...],...],...}",
  "palette": "[{\"id\":1,\"hex\":\"#FF0000\",\"name\":\"Red\"},{\"id\":2,\"hex\":\"#00FF00\",\"name\":\"Green\"}]",
  "symbolMap": "{\"1\":\"X\",\"2\":\"O\"}",
  "uploadedImageUrl": null,
  "createdAt": "2026-03-15T14:35:00+00:00",
  "updatedAt": "2026-03-15T15:10:30+00:00",
  "isDeleted": false,
  "deletedAt": null
}
```

### Example (Soft-Deleted Design)

```json
{
  "id": "019503b2-c3d4-7e5f-9a6b-7c8d9e0f1234",
  "userId": "019503a1-b2c3-7d4e-8f5a-6b7c8d9e0f12",
  "title": "My First Cross-Stitch",
  "width": 100,
  "height": 80,
  "stitchData": "{...}",
  "palette": "[...]",
  "symbolMap": "{...}",
  "uploadedImageUrl": null,
  "createdAt": "2026-03-15T14:35:00+00:00",
  "updatedAt": "2026-03-15T15:10:30+00:00",
  "isDeleted": true,
  "deletedAt": "2026-04-01T09:00:00+00:00"
}
```

---

## Entity Relationship Diagram

```
┌──────────────────────┐         ┌──────────────────────────────┐
│        User          │         │           Design             │
│──────────────────────│         │──────────────────────────────│
│ Id (PK, Guid)        │ 1   *  │ Id (PK, Guid)                │
│ Email (string?)      │───────→│ UserId (FK → User.Id)        │
│ DisplayName (string) │         │ Title (string)               │
│ OAuthProvider (str)  │         │ Width (int)                  │
│ OAuthProviderId (str)│         │ Height (int)                 │
│ CreatedAt (DTO)      │         │ StitchData (JSON, nvarMAX)   │
└──────────────────────┘         │ Palette (JSON, nvarMAX)      │
                                 │ SymbolMap (JSON, nvarMAX)    │
                                 │ UploadedImageUrl (string?)   │
                                 │ CreatedAt (DTO)              │
                                 │ UpdatedAt (DTO)              │
                                 │ IsDeleted (bool)             │
                                 │ DeletedAt (DTO?)             │
                                 └──────────────────────────────┘
```

- One User has many Designs (1:N)
- Each Design belongs to exactly one User
- Soft-delete filter hides IsDeleted=true from normal queries

---

## Migration Strategy

1. **Initial migration**: Create `Users` and `Designs` tables with all indexes
2. EF Core migration: `dotnet ef migrations add AddUserAndDesignEntities --project src/Infrastructure`
3. Apply: `dotnet ef database update --project src/Infrastructure`
4. Seed data: None required (users created on first OAuth sign-in, designs created by users)
