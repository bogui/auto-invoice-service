**Final Project Requirements Document (PRD): Auto-Invoicing Microservice**  
**Version: 1.1**

---

### **1. Overview**

The `auto_invoicing_service` is a Python microservice that automates invoice generation by processing subscription data from a Node.js backend via Redis Streams. It ensures reliability through idempotent workers, integrates with a PDF service, sends emails per tenant settings, and provides operational reports.

---

### **2. Architecture**

#### **2.1 Components**

- **Main Backend (Node.js)**: Publishes subscription jobs to Redis Stream `invoices:jobs` daily at 3 AM.
- **Auto-Invoicing Service (Python)**:
  - Listens to `invoices:jobs` stream using Redis Consumer Groups.
  - Spawns workers for each job, tracks progress, and generates reports.
- **Workers (Python)**:
  - Fetch data via Hasura GraphQL.
  - Generate invoices, trigger PDFs, send emails, and handle retries.
- **PDF Service**: Listens to `pdf:jobs:new`, publishes success/failure to `pdf:jobs:done`/`pdf:jobs:failed`.

#### **2.2 Tech Stack**

- **Python 3.10+**: Async/await with `asyncio`, `aioredis`, and `aiohttp` for HTTP/GraphQL.
- **Redis Streams 7.0+**: For persistent, ordered job processing.
- **Hasura GraphQL v2.0+**: Admin role with headers for row/column permissions.
- **Email**: SMTP or SendGrid (credentials stored in `.env`).
- **pytest**: Unit and Integration testing.
- **Prometheus**: Metrics collection.
- **Docker**: Containerization.

---

### **3. Data Flow**

1. **Job Trigger**:
   - Node.js cron job pushes to Redis Stream `invoices:jobs` with:
     ```json
     {
       "subscription_id": "sub_123",
       "partner_id": "tenant_456",
       "next_billing_date": "2023-10-01",
       "nomenclature_id": 1234,
       "price": 1234,
       "currency_id": "currency_123"
     }
     ```
2. **Processing**:
   - `auto_invoicing_service` reads from `invoices:jobs` using a consumer group.
   - Workers check `pdf:invoice:<invoice_id>:metadata` to avoid duplicates.
3. **Worker Execution**:
   - **Step 1**: Fetch subscription details via Hasura GraphQL (using admin credentials).
   - **Step 2**: Save invoice record in DB via Hasura mutation.
   - **Step 3**: Publish to `pdf:jobs:new` with `job_id` correlation ID.
   - **Step 4**: Listen to `pdf:jobs:done` or `pdf:jobs:failed` for PDF status.
   - **Step 5**: On success, send email (attachment/link per tenant settings).
   - **Step 6**: Retry failed PDF/email jobs (max 3 retries with backoff).
4. **Report**: After all jobs finish, compile success/failure stats and email to managers.

---

### **4. Key Implementation Details**

#### **4.1 Redis Streams & Idempotency**

- Use **Redis Consumer Groups** to distribute jobs across workers.
- Track processed jobs with `processed:<subscription_id>` keys (TTL = 24h) to prevent duplicates.

#### **4.2 PDF Service Integration**

- **Request**: Publish to `pdf:jobs:new` with:
  ```json
  {
    "job_id": "uuid",
    "invoice_id": "inv_123",
    "data": {
      "customer_name": "John Doe",
      "invoice_date": "2023-10-27",
      "items": [
        { "description": "Product A", "quantity": 2, "price": 10.0 },
        { "description": "Service B", "quantity": 1, "price": 50.0 }
      ],
      "total_amount": 70.0
    }
  }
  ```
- **Response**:
  - Success: `pdf:jobs:done` with `{"job_id": "uuid", "file_path": "s3://path"}`.
  - Failure: `pdf:jobs:failed` with `{"job_id": "uuid", "error": "PDF_GENERATION_FAILED"}`.

#### **4.3 Retry Mechanism**

- **PDF/Email Retries**:
  - Include `retry_count` in Redis job metadata.
  - Republish to `invoices:jobs` with `retry_count+1` if `retry_count < 3`.
  - After 3 failures, log to `invoices:jobs:dead` stream for manual review.

#### **4.4 Crash Recovery**

- Use Redis Streams’ `XACK` to confirm job completion.
- Pending jobs (no `XACK` after 30min) are reclaimed by other workers via `XCLAIM`.

#### **4.5 Report Generation**

- Track active jobs with a Redis `INCR`/`DECR` counter.
- When counter reaches zero:
  - Query Redis for `success_count`/`failed_count`.
  - Email report with CSV/HTML summary.

---

### **5. Security**

- **Hasura**: Admin secret passed via `X-Hasura-Admin-Secret` header.
- **Redis**: Deployed in private Docker network; no public ports.
- **Email Credentials**: Stored in `.env` (upgrade to Docker secrets if required).

---

### **6. Testing & Observability**

- **Unit Tests**: 80% coverage enforced via CI/CD (pytest).
- **Mocks**:
  - Redis: `fakeredis` library.
  - PDF Service: Mock HTTP server simulating `pdf:jobs:done/failed`.
- **Monitoring**:
  - **Prometheus Metrics**:
    - `auto_invoicing_job_duration_seconds` (processing time).
    - `auto_invoicing_job_failures_total` (total failures).
    - `redis_stream_invoices_jobs_length` (stream size).
    - `pdf_service_failures_total` (PDF service errors).
  - **Structured Logging (JSON)**:
    - Fields: `Timestamp`, `log level`, `message`, `context` (job ID, subscription ID, error code).
    - Error Codes: `PDF_GENERATION_FAILED`, `HASURA_QUERY_FAILED`, `EMAIL_SEND_FAILED`.

---

### **7. Deployment**

- **Docker**: Service and Redis deployed via `docker-compose.yaml`.
- **Scaling**:
  - Multiple `auto_invoicing_service` instances can join the same Redis consumer group.
  - Report coordination: Leader election via Redis `SETNX`.

---

### **8. Open Risks & Mitigations**

- **Risk**: Hasura GraphQL query bottlenecks under high load.  
  _Mitigation_: Batch requests or cache subscription data.
- **Risk**: PDF service downtime delaying invoices.  
  _Mitigation_: Alert on `pdf:jobs:failed` spikes; fallback to async HTTP retries.

---

### **9. Next Steps**

1. **Finalize PDF Job Payload Schema**: Confirm with PDF service team.
2. **Define Hasura Permissions/Queries**:
   - Example Query:
     ```graphql
     query getSubscription($subscriptionId: String!) {
       subscription(where: {id: {_eq: $subscriptionId}}) { ... }
     }
     ```
   - Example Mutation:
     ```graphql
     mutation insertInvoice($invoice: invoices_insert_input!) {
       insert_invoices_one(object: $invoice) { ... }
     }
     ```
   - Permissions: Read access to subscription data; write access to invoices table.
3. **Implement Worker Retry Logic**: Track `retry_count` in Redis metadata.
4. **Email Templates**:
   - **Subject**: `"Your Invoice [Invoice ID]"`.
   - **Body**: `"Dear Customer, please find your invoice attached/linked below."`.
5. **Error Handling**: Define error codes (`PDF_GENERATION_FAILED`, `HASURA_QUERY_FAILED`, `EMAIL_SEND_FAILED`).
6. **Configuration Management**:
   - `.env` variables:
     ```
     REDIS_HOST, REDIS_PORT, HASURA_ADMIN_SECRET, EMAIL_HOST,
     EMAIL_PORT, EMAIL_USER, EMAIL_PASSWORD, SENDGRID_API_KEY
     ```
   - Configuration changes applied by restarting Docker containers.

---

**Approvals**:

- [ ] Architecture sign-off.
- [ ] Redis Streams implementation.
- [ ] Hasura integration plan.
