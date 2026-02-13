using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

/// <summary>
/// Health check endpoint for monitoring application status.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    /// <summary>
    /// Returns the health status of the application.
    /// </summary>
    /// <returns>A health status object with status and timestamp.</returns>
    /// <response code="200">Application is healthy</response>
    [HttpGet]
    [ProducesResponseType(typeof(HealthResponse), StatusCodes.Status200OK)]
    public IActionResult Get()
    {
        var response = new HealthResponse
        {
            Status = "healthy",
            Timestamp = DateTime.UtcNow
        };

        return Ok(response);
    }
}

/// <summary>
/// Health check response model.
/// </summary>
public record HealthResponse
{
    /// <summary>
    /// The health status of the application.
    /// </summary>
    public required string Status { get; init; }

    /// <summary>
    /// The timestamp of the health check.
    /// </summary>
    public required DateTime Timestamp { get; init; }
}
