#!/bin/bash
# Run smoke tests against deployed environment
# Usage: ./smoke-test.sh <environment>
# Example: ./smoke-test.sh staging

set -e

ENVIRONMENT=${1:-staging}
TIMEOUT=30
MAX_RETRIES=3

# Get App Service URL based on environment
case "${ENVIRONMENT}" in
    dev)
        BASE_URL="https://app-stitches-dev.azurewebsites.net"
        ;;
    staging)
        BASE_URL="https://app-stitches-staging.azurewebsites.net"
        ;;
    prod)
        BASE_URL="https://app-stitches-prod.azurewebsites.net"
        ;;
    *)
        echo "❌ Invalid environment: ${ENVIRONMENT}"
        echo "   Valid values: dev, staging, prod"
        exit 1
        ;;
esac

HEALTH_ENDPOINT="${BASE_URL}/api/health"

echo "🔍 Running smoke tests for environment: ${ENVIRONMENT}"
echo "   Health endpoint: ${HEALTH_ENDPOINT}"

# Retry loop for health check
for i in $(seq 1 ${MAX_RETRIES}); do
    echo ""
    echo "⏳ Attempt ${i}/${MAX_RETRIES}: Checking health endpoint..."
    
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time ${TIMEOUT} "${HEALTH_ENDPOINT}" 2>/dev/null || echo "000")
    
    if [ "${HTTP_STATUS}" -eq 200 ]; then
        echo "✅ Health check passed! HTTP Status: ${HTTP_STATUS}"
        
        # Get response body for additional validation
        RESPONSE=$(curl -s --max-time ${TIMEOUT} "${HEALTH_ENDPOINT}")
        echo "   Response: ${RESPONSE}"
        
        # Validate response contains expected fields
        if echo "${RESPONSE}" | grep -q '"status":"healthy"'; then
            echo "✅ Response validation passed!"
            echo ""
            echo "🎉 All smoke tests passed!"
            exit 0
        else
            echo "❌ Response validation failed: Expected status='healthy'"
            exit 1
        fi
    else
        echo "⚠️  Health check returned HTTP ${HTTP_STATUS}"
        
        if [ ${i} -lt ${MAX_RETRIES} ]; then
            echo "   Waiting 10 seconds before retry..."
            sleep 10
        fi
    fi
done

echo ""
echo "❌ Smoke test failed after ${MAX_RETRIES} attempts"
echo "   Last HTTP status: ${HTTP_STATUS}"
exit 1
