# Architecture Patterns Reference

## Table of Contents

1. [Monolithic Architecture](#monolithic-architecture)
2. [Modular Monolith](#modular-monolith)
3. [Microservices](#microservices)
4. [Serverless](#serverless)
5. [Event-Driven Architecture](#event-driven-architecture)
6. [Decision Matrix](#decision-matrix)

---

## Monolithic Architecture

**Best for**: MVPs, small teams (1-5 devs), apps with <10k daily users.

**Pattern**: Single deployable unit containing all application logic.

```
┌─────────────────────────────┐
│         Monolith            │
│  ┌─────┐ ┌─────┐ ┌─────┐  │
│  │ UI  │ │ API │ │ BIZ │  │
│  └─────┘ └─────┘ └─────┘  │
│  ┌─────────────────────┐   │
│  │      Database       │   │
│  └─────────────────────┘   │
└─────────────────────────────┘
```

**Pros**: Simple deployment, easy debugging, low latency (in-process calls), easy to test end-to-end.

**Cons**: Scaling is all-or-nothing, deployment risk increases with size, technology lock-in, team coupling.

**When to recommend**: Early-stage startups, proof of concepts, internal tools, apps where time-to-market matters most.

---

## Modular Monolith

**Best for**: Growing teams (5-15 devs), apps planning for scale, teams wanting microservices benefits without complexity.

**Pattern**: Single deployable unit with strictly enforced module boundaries.

```
┌──────────────────────────────────┐
│          Modular Monolith        │
│  ┌────────┐ ┌────────┐ ┌──────┐ │
│  │ Users  │ │ Orders │ │ Pay  │ │
│  │ Module │ │ Module │ │ Mod  │ │
│  │ ────── │ │ ────── │ │ ──── │ │
│  │ API    │ │ API    │ │ API  │ │
│  │ Domain │ │ Domain │ │ Dom  │ │
│  │ Data   │ │ Data   │ │ Data │ │
│  └────────┘ └────────┘ └──────┘ │
│         Shared Kernel            │
└──────────────────────────────────┘
```

**Pros**: Clear boundaries without network overhead, modules can be extracted to services later, simpler ops than microservices, strong encapsulation.

**Cons**: Requires discipline to maintain boundaries, single deployment still, shared database can leak coupling.

**When to recommend**: Teams that want to "grow into" microservices, domain-heavy applications, when team structure doesn't yet justify distributed systems.

---

## Microservices

**Best for**: Large teams (15+ devs), high-scale apps (100k+ users), organizations with strong DevOps maturity.

**Pattern**: Multiple independently deployable services communicating over network.

**Pros**: Independent scaling and deployment, technology diversity, team autonomy, fault isolation.

**Cons**: Network complexity, distributed debugging is hard, data consistency challenges, operational overhead (service mesh, observability, etc.).

**When to recommend**: Only when the team has DevOps maturity AND either the scale demands it or team size requires independent deployment.

**Anti-pattern warning**: Microservices for small teams = distributed monolith. Always warn against premature microservices.

---

## Serverless

**Best for**: Event-driven workloads, variable traffic patterns, teams wanting minimal ops.

**Pattern**: Functions-as-a-Service with managed backing services.

**Pros**: Zero server management, pay-per-use, auto-scaling, fast prototyping.

**Cons**: Cold starts, vendor lock-in, execution time limits, debugging difficulty, state management complexity.

**When to recommend**: APIs with variable traffic, event processing, scheduled tasks, backends for mobile apps with unpredictable usage.

---

## Event-Driven Architecture

**Best for**: Systems requiring loose coupling, real-time processing, audit trails.

**Pattern**: Components communicate through events via a message broker.

**Pros**: Extreme loose coupling, natural audit trail, temporal decoupling, easy to add new consumers.

**Cons**: Eventual consistency, debugging event flows, message ordering complexity, potential for event storms.

**When to recommend**: Often combined with other patterns. Use when multiple systems need to react to the same business events.

---

## Decision Matrix

| Factor | Monolith | Modular Monolith | Microservices | Serverless |
|--------|----------|-------------------|---------------|------------|
| Team size | 1-5 | 5-15 | 15+ | 1-10 |
| Time to market | Fast | Fast | Slow | Fast |
| Ops complexity | Low | Low | High | Low |
| Scaling granularity | Low | Low | High | High |
| Technology flexibility | Low | Medium | High | Medium |
| Cost at low scale | Low | Low | High | Very low |
| Cost at high scale | High | Medium | Medium | Variable |
| DevOps maturity needed | Low | Low | High | Medium |
