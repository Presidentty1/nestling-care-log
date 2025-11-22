# ADR 006: Supabase as Backend-as-a-Service

## Status
Accepted

## Context
The application needed a backend for data synchronization, authentication, and server-side processing. Traditional backend development would be time-consuming and costly for an early-stage startup.

## Decision
We chose Supabase as the primary backend-as-a-service platform for data storage, authentication, and serverless functions.

## Rationale
- **Developer Productivity**: Pre-built authentication, database, and API endpoints
- **PostgreSQL**: Robust, reliable database with advanced features
- **Real-time**: Built-in real-time subscriptions for data synchronization
- **Authentication**: Multiple auth providers with secure token management
- **Edge Functions**: Serverless functions for AI processing and business logic
- **Pricing**: Generous free tier for early-stage development
- **Ecosystem**: Rich ecosystem of tools and integrations
- **Type Safety**: TypeScript support and generated client libraries

## Consequences
- **Positive**:
  - Rapid development and deployment
  - Built-in security features and best practices
  - Scalable infrastructure without DevOps overhead
  - Rich feature set out of the box

- **Negative**:
  - Vendor lock-in to Supabase ecosystem
  - Limited customization of underlying infrastructure
  - Dependency on Supabase's roadmap and pricing changes
  - Learning curve for Supabase-specific features

## Implementation
- **Database**: PostgreSQL with Row Level Security (RLS) policies
- **Authentication**: Supabase Auth with email/password and social providers
- **API**: Auto-generated REST API with real-time capabilities
- **Edge Functions**: Serverless functions for AI features and complex business logic
- **Client Libraries**: Official Swift and JavaScript/TypeScript clients
- **Migrations**: SQL migrations for database schema changes

## Security Considerations
- Row Level Security enabled on all tables
- Authentication required for all data operations
- API keys properly secured through environment variables
- Regular security audits of Supabase configuration

## Alternatives Considered
- **Firebase**: Similar offering, but Supabase had better PostgreSQL support
- **Custom Backend**: Too time-consuming and costly for MVP
- **AWS Amplify**: More complex setup and higher learning curve
- **PlanetScale + Vercel**: Would require more infrastructure setup

## Related Decisions
- ADR 003: Offline-First Architecture
- ADR 007: Capacitor for Cross-Platform Mobile




