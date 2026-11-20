# Root Dockerfile for Fly.io / any repo-root build.
# The real signer Dockerfile lives in signer/ and expects that directory as
# build context; this one copies it explicitly so `fly deploy` from the repo
# root works unchanged.
FROM --platform=$BUILDPLATFORM eclipse-temurin:21-jdk AS build
WORKDIR /src
COPY signer/gradlew signer/settings.gradle.kts signer/build.gradle.kts ./
COPY signer/gradle gradle
RUN sed -i "s/\r$//" gradlew && chmod +x gradlew
RUN ./gradlew --no-daemon -q help
COPY signer/src src
RUN ./gradlew --no-daemon -q installDist

FROM eclipse-temurin:21-jre
RUN useradd --system --uid 10001 --home-dir /app openhongguo
COPY --from=build /src/build/install/openhongguo-signer /app
USER openhongguo
WORKDIR /app
ENV SIGNER_HOST=0.0.0.0 \
    SIGNER_PORT=19830 \
    JAVA_OPTS="-XX:MaxRAMPercentage=75 -Djava.io.tmpdir=/tmp"
EXPOSE 19830
ENTRYPOINT ["/app/bin/openhongguo-signer"]
