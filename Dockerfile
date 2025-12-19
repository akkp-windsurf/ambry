# Multi-stage Dockerfile for Ambry
# This Dockerfile builds all Ambry components (Server, VCR, Frontend)

# =============================================================================
# Build Stage
# =============================================================================
FROM gradle:8-jdk11 AS builder

WORKDIR /app

# Copy gradle wrapper and build files first for better caching
COPY gradlew gradlew.bat ./
COPY gradle/ gradle/
COPY build.gradle settings.gradle gradle.properties version.properties ./

# Copy source code
COPY ambry-account/ ambry-account/
COPY ambry-api/ ambry-api/
COPY ambry-cloud/ ambry-cloud/
COPY ambry-clustermap/ ambry-clustermap/
COPY ambry-commons/ ambry-commons/
COPY ambry-file-transfer/ ambry-file-transfer/
COPY ambry-filesystem/ ambry-filesystem/
COPY ambry-frontend/ ambry-frontend/
COPY ambry-messageformat/ ambry-messageformat/
COPY ambry-mysql/ ambry-mysql/
COPY ambry-named-mysql/ ambry-named-mysql/
COPY ambry-network/ ambry-network/
COPY ambry-prioritization/ ambry-prioritization/
COPY ambry-protocol/ ambry-protocol/
COPY ambry-quota/ ambry-quota/
COPY ambry-replication/ ambry-replication/
COPY ambry-rest/ ambry-rest/
COPY ambry-router/ ambry-router/
COPY ambry-server/ ambry-server/
COPY ambry-store/ ambry-store/
COPY ambry-test-utils/ ambry-test-utils/
COPY ambry-tools/ ambry-tools/
COPY ambry-utils/ ambry-utils/
COPY ambry-vcr/ ambry-vcr/
COPY ambry-all/ ambry-all/
COPY log4j-test-config/ log4j-test-config/

# Build the uber JARs (skip tests for faster builds)
RUN ./gradlew allJar allJarVcr -x test --no-daemon

# =============================================================================
# Runtime Stage
# =============================================================================
FROM openjdk:11-jre-slim AS runtime

# Install necessary packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r ambry && useradd -r -g ambry ambry

WORKDIR /opt/ambry

# Copy built JARs from builder stage
COPY --from=builder /app/target/ambry.jar ./ambry.jar
COPY --from=builder /app/target/ambry-vcr.jar ./ambry-vcr.jar

# Copy configuration files
COPY config/ ./config/

# Create logs directory
RUN mkdir -p logs && chown -R ambry:ambry /opt/ambry

# Switch to non-root user
USER ambry

# Default environment variables
ENV JAVA_OPTS="-Xmx4g -Xms1g"
ENV LOG4J_CONFIG="/opt/ambry/config/log4j2.xml"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:1174/healthCheck || exit 1

# Default command (can be overridden)
# Use AmbryMain for server, VcrMain for VCR, AmbryFrontendMain for frontend
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -Dlog4j2.configurationFile=file:$LOG4J_CONFIG -jar ambry.jar --serverPropsFilePath ${SERVER_PROPS:-/opt/ambry/config/server.properties} --hardwareLayoutFilePath ${HARDWARE_LAYOUT:-/opt/ambry/config/HardwareLayout.json} --partitionLayoutFilePath ${PARTITION_LAYOUT:-/opt/ambry/config/PartitionLayout.json}"]

# Expose common ports
# 6667 - Server port
# 1174 - Frontend HTTP port
# 6668 - SSL port
EXPOSE 6667 1174 6668
