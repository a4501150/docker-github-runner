# docker-github-runner

A self-hosted GitHub Actions runner packaged as a Docker image. Based on Ubuntu 22.04 with Docker-in-Docker support.

## Usage

Copy `.env.example` to `.env` and fill in your values, then start the runner:

```bash
docker compose up -d
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

### Commit Messages

This project uses [conventional commits](https://www.conventionalcommits.org/) with [release-please](https://github.com/googleapis/release-please) for automated releases:

- `feat: <description>` -- new feature (bumps minor version)
- `fix: <description>` -- bug fix (bumps patch version)
- `feat!: <description>` -- breaking change (bumps major version)
- `chore:`, `docs:`, `refactor:` -- no version bump

## License

Apache-2.0
