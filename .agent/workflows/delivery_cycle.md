---
description: Full delivery cycle from requirements to deployment, review, and commit
---

# Delivery Cycle Workflow

Follow these steps for any major feature or bug fix to ensure quality and user satisfaction.

## 1. Requirement Gathering & Planning
Before writing any code, understand the user's needs and plan the implementation.

// turbo
```bash
./scripts/delivery_cycle.sh plan "Your requirement here"
```
- Create or update [implementation_plan.md](file:///Users/duylong/.gemini/antigravity/brain/c558da1b-b2ad-42da-8e21-c646e003a26f/implementation_plan.md).
- Use `notify_user` to request review of the plan.

## 2. Implementation & Local Verification
Implement the changes as planned and verify them locally.

- Write the code and run local tests.
- Update [task.md](file:///Users/duylong/.gemini/antigravity/brain/c558da1b-b2ad-42da-8e21-c646e003a26f/task.md) as you progress.

## 3. Deployment for Review
Push the changes to a platform where the user can test them.

### Option A: TestFlight (Mobile)
// turbo
```bash
./scripts/delivery_cycle.sh deploy testflight
```

### Option B: Web (Hosting/Preview)
// turbo
```bash
./scripts/delivery_cycle.sh deploy web
```

## 4. User Check & Review
Document what was done and ask the user to verify.

- Create or update [walkthrough.md](file:///Users/duylong/.gemini/antigravity/brain/c558da1b-b2ad-42da-8e21-c646e003a26f/walkthrough.md).
- Use `notify_user`.

## 5. Finalize & Commit
Only proceed if the user gives explicit approval.

// turbo
```bash
./scripts/delivery_cycle.sh commit "Summary of changes"
```

---
> [!IMPORTANT]
> Never skip the user review step. High quality and user satisfaction are the priorities.
