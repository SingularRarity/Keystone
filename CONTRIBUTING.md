# Contributing to Keystone

## Development Setup

1. Clone the repository
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. Build tools: `npm run build`

## Code Standards

- TypeScript for adapters and tools
- Bash/PowerShell for setup scripts
- Markdown for skill definitions
- Follow existing naming conventions

## Testing

- Test all skills with sample inputs
- Verify output schemas match specifications
- Test cross-platform compatibility (Windows/macOS/Linux)
- Validate token compression ratios

## Pull Request Process

1. Create feature branch from `main`
2. Write tests for new functionality
3. Update documentation
4. Ensure CI passes
5. Request review from maintainers

## Architecture Decisions

All significant changes require an ADR in `/decisions/` following the established template.