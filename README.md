# openDesk SOGo Image

Custom SOGo image with OIDC/SSO support for openDesk Edu.
Based on Debian Bookworm with SOGo 5.12.9, Apache 2, and Supervisor.

## Features
- SOGo groupware (mail, calendar, contacts)
- OIDC/SSO via Keycloak (SOGoOpenId)
- OpenCloud file picker integration (WebDAV)
- LDAP user directory
- Stalwart IMAP/SMTP/Sieve backend
- Supervisor-managed processes (SOGo + Apache)

## Registries
- `registry.gitlab.com/tbsweiss/opendesk-sogo-image` (primary)
- `registry.hrz.uni-marburg.de/opendesk/sogo` (HRZ mirror)
- `docker.io/weissto/sogo` (Docker Hub, may be rate-limited)

## Tags
- `bookworm-5.12.9` — SOGo 5.12.9 on Debian Bookworm
- `latest` — latest stable

## Build
```bash
docker build -t opendesk-sogo .
```

## License
AGPL-3.0 (SOGo is AGPL)
