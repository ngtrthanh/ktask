# Task: Implement rate limiting middleware

## Description
Add a request rate limiter to the API that restricts each IP to 100 requests per minute and returns 429 on breach.

## Checklist
- [ ] Read existing middleware setup to understand the pattern
- [ ] Implement in-memory sliding window rate limiter
- [ ] Register middleware on all /api/* routes
- [ ] Return JSON error body with retry-after header on 429
