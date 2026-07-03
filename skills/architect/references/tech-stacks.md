# Tech Stack Reference Guide

> **Last updated: 2026-03.** Ecosystem data ages fast — when live WebSearch
> results conflict with this file, trust the search.

## Table of Contents

1. [Frontend Frameworks](#frontend-frameworks)
2. [Backend Frameworks](#backend-frameworks)
3. [Databases](#databases)
4. [Authentication](#authentication)
5. [API Design](#api-design)
6. [DevOps & Deployment](#devops--deployment)
7. [Monitoring & Observability](#monitoring--observability)
8. [CSS & Styling](#css--styling)
9. [State Management](#state-management)
10. [Testing Frameworks](#testing-frameworks)
11. [Popular Stack Combinations](#popular-stack-combinations)

---

## Frontend Frameworks

### React
- **Type**: Library (UI layer)
- **Ecosystem**: Massive, most job market demand
- **Best for**: SPAs, complex UIs, large teams, apps needing rich ecosystem
- **Cons**: Not opinionated (decision fatigue), requires additional libraries for routing/state
- **Meta-frameworks**: Next.js (SSR/SSG), Remix (full-stack), Vite+React (SPA)

### Vue.js
- **Type**: Progressive framework
- **Ecosystem**: Strong, growing
- **Best for**: Gradual adoption, smaller teams, developers who prefer convention over configuration
- **Cons**: Smaller talent pool than React
- **Meta-frameworks**: Nuxt.js (SSR/SSG)

### Angular
- **Type**: Full framework (batteries included)
- **Ecosystem**: Enterprise-focused
- **Best for**: Large enterprise apps, teams wanting opinionated structure, TypeScript-first
- **Cons**: Steeper learning curve, heavier bundle, slower iteration

### Svelte / SvelteKit
- **Type**: Compiler-based framework
- **Ecosystem**: Growing rapidly
- **Best for**: Performance-critical apps, smaller bundles, developer experience
- **Cons**: Smaller ecosystem, fewer third-party components

### Solid.js
- **Type**: Reactive library (React-like API, no virtual DOM)
- **Best for**: Performance-critical SPAs
- **Cons**: Small ecosystem, niche adoption

### HTMX
- **Type**: HTML-driven interactivity
- **Best for**: Server-rendered apps needing dynamic behavior without SPA complexity
- **Cons**: Not suitable for highly interactive UIs

### Comparison Table

| Factor | React | Vue | Angular | Svelte | HTMX |
|--------|-------|-----|---------|--------|------|
| Learning curve | Medium | Low | High | Low | Very low |
| Bundle size | Medium | Small | Large | Very small | Tiny |
| Ecosystem | Huge | Large | Large | Growing | Small |
| TypeScript | Good | Good | Native | Good | N/A |
| Hiring pool | Largest | Medium | Medium | Small | Small |
| Performance | Good | Good | Good | Excellent | N/A |

---

## Backend Frameworks

### Node.js Ecosystem
- **Express.js**: Minimal, flexible. Best for: simple APIs, microservices.
- **Fastify**: Express alternative with better performance and schema validation.
- **NestJS**: Opinionated, Angular-inspired. Best for: enterprise Node.js apps.
- **Hono**: Ultra-fast, edge-first. Best for: serverless, edge computing.

### Python Ecosystem
- **FastAPI**: Modern, async, auto-docs. Best for: APIs, ML-serving, rapid prototyping.
- **Django**: Batteries-included. Best for: content-heavy apps, admin interfaces, rapid development.
- **Flask**: Minimal, flexible. Best for: simple APIs, microservices.

### Go
- **Standard library**: Often sufficient. Best for: high-performance services, CLI tools.
- **Gin / Echo / Fiber**: Lightweight frameworks. Best for: REST APIs needing Go performance.

### Rust
- **Actix Web / Axum**: Best for: extreme performance requirements, systems programming background.

### Java / Kotlin
- **Spring Boot**: Enterprise standard. Best for: large enterprise apps, existing Java teams.
- **Quarkus**: Cloud-native Java. Best for: containerized Java microservices.
- **Ktor**: Kotlin-native. Best for: Kotlin-first teams.

### C# / .NET
- **ASP.NET Core**: Microsoft ecosystem. Best for: enterprise apps, existing .NET teams.

### Comparison Table

| Factor | Node/Express | NestJS | FastAPI | Django | Go stdlib | Spring Boot |
|--------|-------------|--------|---------|--------|-----------|-------------|
| Performance | Good | Good | Very Good | Moderate | Excellent | Good |
| Learning curve | Low | Medium | Low | Medium | Medium | High |
| Ecosystem | Huge | Large | Growing | Huge | Moderate | Huge |
| Type safety | With TS | Native TS | Native | Optional | Native | Native |
| Rapid prototyping | Fast | Medium | Fast | Very fast | Slower | Slower |
| Enterprise readiness | Medium | High | Medium | High | High | Very high |

---

## Databases

### Relational (SQL)
- **PostgreSQL**: Feature-rich, extensible (JSONB, full-text search, PostGIS). Default recommendation for most apps.
- **MySQL/MariaDB**: Simpler, fast reads. Good for read-heavy workloads.
- **SQLite**: Embedded, zero-config. Great for development, small apps, edge computing.

### Document (NoSQL)
- **MongoDB**: Flexible schema, horizontal scaling. Good for: content management, catalogs, rapid prototyping.
- **CouchDB**: Offline-first sync. Good for: mobile apps with offline support.

### Key-Value
- **Redis**: In-memory, blazing fast. Use for: caching, sessions, queues, real-time features.
- **DynamoDB**: Managed, serverless. Use for: AWS-native apps needing predictable latency.

### Graph
- **Neo4j**: Relationship-heavy data. Use for: social networks, recommendation engines, knowledge graphs.

### Time Series
- **TimescaleDB** (PostgreSQL extension): Use for: IoT, metrics, analytics.
- **InfluxDB**: Purpose-built. Use for: monitoring, metrics.

### Search
- **Elasticsearch / OpenSearch**: Full-text search, log analytics.
- **Meilisearch / Typesense**: Lightweight search. Good for: product search, autocomplete.

### Vector
- **pgvector** (PostgreSQL extension): Vector similarity search within PostgreSQL.
- **Pinecone / Weaviate / Qdrant**: Purpose-built vector DBs for AI/ML applications.

### Decision Guide

| Need | Recommended |
|------|-------------|
| Default / general purpose | PostgreSQL |
| Caching layer | Redis |
| Flexible schema, rapid iteration | MongoDB |
| Full-text search | Elasticsearch or PostgreSQL (built-in) |
| AI/ML embeddings | pgvector or Pinecone |
| Offline-first mobile | CouchDB or SQLite |
| Time-series / IoT | TimescaleDB |

---

## Authentication

### Strategies
- **Session-based**: Server stores session. Simple, good for server-rendered apps.
- **JWT (stateless)**: Token-based. Good for SPAs, mobile apps, microservices.
- **OAuth 2.0 / OIDC**: Delegated auth. Required for social login, enterprise SSO.
- **Passkeys / WebAuthn**: Passwordless. Modern, most secure for end-users.
- **Magic links**: Email-based passwordless. Good UX, simple implementation.

### Providers & Libraries
- **Auth.js (NextAuth)**: For Next.js apps. Supports many providers.
- **Clerk**: Managed auth with UI components. Fast to integrate.
- **Auth0**: Managed auth platform. Enterprise-grade.
- **Supabase Auth**: Open-source, PostgreSQL-based. Good for Supabase users.
- **Keycloak**: Self-hosted, enterprise SSO. Open-source.
- **Firebase Auth**: Google-managed. Good for mobile + web.
- **Passport.js**: Node.js middleware. Flexible but more manual.
- **Django Auth**: Built-in. Complete for Django apps.

### Decision Guide

| Scenario | Recommendation |
|----------|---------------|
| SPA + API | JWT with refresh tokens + OAuth 2.0 |
| Server-rendered app | Session-based or Auth.js |
| Enterprise / SSO | Keycloak or Auth0 |
| Fast MVP | Clerk or Supabase Auth |
| Mobile app | Firebase Auth or OAuth 2.0 with PKCE |

---

## API Design

### REST
- Standard HTTP methods, resource-based URLs
- Best for: CRUD operations, public APIs, broad compatibility

### GraphQL
- Single endpoint, client-defined queries
- Best for: Complex data relationships, mobile apps needing minimal payloads, frontend-driven teams
- Cons: Caching complexity, N+1 query risk, learning curve

### tRPC
- End-to-end TypeScript type safety, no code generation
- Best for: Full-stack TypeScript apps (Next.js, SvelteKit)
- Cons: TypeScript-only, not suitable for public APIs

### gRPC
- Protocol Buffers, high performance, bi-directional streaming
- Best for: Internal microservice communication, performance-critical services
- Cons: Not browser-native (needs proxy), complex setup

### Decision Guide

| Scenario | Recommendation |
|----------|---------------|
| Public API | REST with OpenAPI spec |
| Full-stack TypeScript | tRPC |
| Complex frontend queries | GraphQL |
| Microservice-to-microservice | gRPC |
| Simple CRUD app | REST |

---

## DevOps & Deployment

### Hosting / Platforms
- **Vercel**: Best for Next.js, frontend-focused deployments
- **Railway / Render**: Simple full-stack hosting with databases
- **Fly.io**: Edge deployment, good for low-latency global apps
- **AWS / GCP / Azure**: Full cloud platforms. Use when you need fine-grained control
- **DigitalOcean App Platform**: Simple, affordable cloud hosting
- **Coolify / Dokku**: Self-hosted PaaS alternatives

### Containerization
- **Docker**: Container standard. Always recommend for production consistency
- **Docker Compose**: Multi-container local development
- **Kubernetes**: Container orchestration. Only for large-scale or multi-team setups

### CI/CD
- **GitHub Actions**: Tightly integrated with GitHub. Most common choice
- **GitLab CI/CD**: Built into GitLab. Good for GitLab users
- **CircleCI / Travis CI**: Third-party CI. Mature but less common now

### Infrastructure as Code
- **Terraform**: Cloud-agnostic IaC. Standard choice
- **Pulumi**: IaC with real programming languages
- **AWS CDK**: AWS-specific IaC with TypeScript/Python

---

## Monitoring & Observability

### Application Performance
- **Sentry**: Error tracking + performance monitoring. Most popular
- **Datadog**: Full observability platform. Enterprise
- **New Relic**: APM. Enterprise
- **Grafana + Prometheus**: Open-source monitoring stack

### Logging
- **ELK Stack** (Elasticsearch, Logstash, Kibana): Full-featured log management
- **Loki + Grafana**: Lightweight log aggregation
- **Axiom**: Modern, cost-effective log management

### Uptime / Alerting
- **Better Uptime / UptimeRobot**: Simple uptime monitoring
- **PagerDuty / Opsgenie**: Incident management

---

## CSS & Styling

| Solution | Best For | Pros | Cons |
|----------|----------|------|------|
| Tailwind CSS | Most projects | Utility-first, fast, consistent | HTML verbosity |
| CSS Modules | Component isolation | No naming conflicts, simple | Verbose imports |
| styled-components | Runtime theming | Dynamic styles, co-location | Runtime cost |
| Vanilla Extract | Type-safe CSS | Zero runtime, type-safe | Build setup |
| shadcn/ui | React component library | Copy-paste components, Tailwind-based | React only |

---

## State Management

### React
- **React Context + useReducer**: Built-in, simple. For light state needs.
- **Zustand**: Minimal, no boilerplate. Recommended default for React.
- **TanStack Query (React Query)**: Server state management. Always recommend for API data.
- **Jotai / Recoil**: Atomic state. For complex, interconnected state.
- **Redux Toolkit**: Established, powerful. For large apps with complex state logic.

### Vue
- **Pinia**: Official store. Simple, TypeScript-friendly.

### General
- **XState**: State machines. For complex UI workflows with clear states.

---

## Testing Frameworks

| Layer | Tools | Notes |
|-------|-------|-------|
| Unit | Vitest, Jest | Vitest preferred for Vite-based projects |
| Component | Testing Library, Storybook | Testing Library for behavior, Storybook for visual |
| Integration | Supertest, MSW | MSW for API mocking |
| E2E | Playwright, Cypress | Playwright recommended for new projects |
| API | Bruno, Hoppscotch | Postman alternatives |

---

## Popular Stack Combinations

### T3 Stack (TypeScript Full-Stack)
Next.js + tRPC + Prisma + NextAuth + Tailwind
**Best for**: Full-stack TypeScript apps, type-safety fanatics

### MERN Stack
MongoDB + Express + React + Node.js
**Best for**: JavaScript everywhere, rapid prototyping

### Django + React/Vue
Django REST Framework + React/Vue frontend
**Best for**: Python teams, data-heavy apps, admin interfaces needed

### Go + HTMX
Go stdlib + HTMX + Alpine.js
**Best for**: Performance-focused, minimal JavaScript, server-rendered

### Laravel + Vue/React (TALL/VILT)
Laravel + Tailwind + Alpine/Vue + Livewire
**Best for**: PHP teams, rapid full-stack development

### Next.js + Supabase
Next.js + Supabase (PostgreSQL + Auth + Storage + Realtime)
**Best for**: Fast MVPs, indie hackers, BaaS approach

### Spring Boot + Angular
Spring Boot + Angular + PostgreSQL
**Best for**: Enterprise Java teams, large organizations
