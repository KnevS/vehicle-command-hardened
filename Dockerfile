# Gehärteter Build von Teslas tesla-http-proxy (github.com/teslamotors/vehicle-command).
#
# Unterschiede zum offiziellen Image tesla/vehicle-command:
#   - aktuelles Go statt golang:1.23.0 (behebt die stdlib-CVEs)
#   - statisch gelinkt (CGO_ENABLED=0) auf distroless/static: keine libc, keine libssl
#   - Quellcode fest auf einen geprüften Upstream-Commit, Basis-Images per Digest
#   - nur das Proxy-Binary, nicht alle Werkzeuge des Repos
#
# Upstream-Version ändern: UPSTREAM_TAG und UPSTREAM_COMMIT gemeinsam anpassen.

ARG UPSTREAM_TAG=v0.4.1
ARG UPSTREAM_COMMIT=49977a18fd68567501d59e16a6c9e4a8b9348544

FROM golang:1.27.2-bookworm@sha256:5cf287a799e6b94384bad13d16b14904c531f51ba65792237e122ce42b392f61 AS build
ARG UPSTREAM_TAG
ARG UPSTREAM_COMMIT
WORKDIR /src

# Tag holen und gegen den erwarteten Commit prüfen: ein verschobener Tag bricht den Build ab.
RUN git clone --depth 1 --branch "$UPSTREAM_TAG" https://github.com/teslamotors/vehicle-command.git . \
    && test "$(git rev-parse HEAD)" = "$UPSTREAM_COMMIT"

RUN go mod download && go mod verify
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/tesla-http-proxy ./cmd/tesla-http-proxy

FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
ARG UPSTREAM_TAG
ARG UPSTREAM_COMMIT
LABEL org.opencontainers.image.title="vehicle-command-hardened" \
      org.opencontainers.image.description="tesla-http-proxy aus teslamotors/vehicle-command, mit aktuellem Go statisch gebaut" \
      org.opencontainers.image.source="https://github.com/KnevS/vehicle-command-hardened" \
      org.opencontainers.image.version="${UPSTREAM_TAG}" \
      org.opencontainers.image.revision="${UPSTREAM_COMMIT}" \
      org.opencontainers.image.licenses="Apache-2.0"

COPY --from=build /out/tesla-http-proxy /usr/local/bin/tesla-http-proxy
USER nonroot
ENTRYPOINT ["tesla-http-proxy"]
