---
description: "Enforce EARS (Easy Approach to Requirements Syntax) for writing clear, unambiguous, and testable software requirements"
category: "requirements"
version: "1.0.0"
status: "stable"
created: "2025-01-17"
updated: "2025-01-17"
authors: ["A. T."]
related:
  - "../markdown/markdown-formatting.md"
deprecated: false
globs: ["**/requirements/**/*.md", "**/specs/**/*.md", "REQUIREMENTS.md"]
alwaysApply: false
---

# EARS: Easy Approach to Requirements Syntax

## Cohesion Principle

**Why These Patterns Belong Together:**

EARS provides a unified syntax for expressing all types of software requirements through five complementary patterns. These patterns form a cohesive system where:

1. **Ubiquitous Requirements**: Express unconditional system behaviors that always apply
2. **Event-Driven Requirements**: Capture system responses to triggering events
3. **State-Driven Requirements**: Define behaviors active under specific conditions
4. **Optional Feature Requirements**: Scope behaviors to conditional product features
5. **Unwanted Behavior Requirements**: Specify system responses to error conditions

These patterns are interdependent and follow the same temporal structure (precondition → trigger → system → response), ensuring consistency across requirement types while addressing different behavioral needs. Together, they eliminate the ambiguity of unconstrained natural language while remaining human-readable.

## Description

EARS (Easy Approach to Requirements Syntax) is a structured natural language notation for writing software requirements. Published in 2009 by Alistair Mavin and colleagues at Rolls-Royce, EARS addresses the inherent imprecision of unconstrained natural language requirements by providing five syntactic patterns that cover all common requirement types.

EARS requirements follow a consistent temporal structure with specific keywords (While, When, Where, If-Then) that clearly define preconditions, triggers, and system responses. This structured approach reduces ambiguity, improves testability, and minimizes requirements volatility throughout the development lifecycle.

## Rule

### Fundamental Syntax Structure

**MANDATORY**: All EARS requirements follow this temporal pattern:

```text
"While <optional precondition>, when <optional trigger>, the <system name> shall <system response>"
```

**Core Constraints**:
- Zero or many preconditions (use "While")
- Zero or one trigger (use "When")
- Exactly one system name (explicitly named)
- One or many system responses
- Clauses must appear in temporal order

### 1. Ubiquitous Requirements (No Keywords)

**MANDATORY**: Use for requirements that are always active with no preconditions or triggers.

**Template**:
```text
The [system name] shall [system response]
```

**When to Use**:
- Unconditional system behaviors
- Always-active constraints
- Continuous monitoring requirements

**Example**:
```text
✅ CORRECT: The mobile phone shall have a mass less than 150 grams
✅ CORRECT: The API shall respond within 200 milliseconds
✅ CORRECT: The system shall log all authentication attempts
```

### 2. Event-Driven Requirements (Keyword: When)

**MANDATORY**: Use for requirements triggered by specific events.

**Template**:
```text
When [trigger event], the [system name] shall [system response]
```

**When to Use**:
- User actions requiring system response
- External events triggering behavior
- Time-based triggers

**Examples**:
```text
✅ CORRECT: When the user presses the mute button, the laptop shall mute audio output
✅ CORRECT: When a new order is received, the system shall send a confirmation email
✅ CORRECT: When the timeout expires, the service shall close the connection
```

### 3. State-Driven Requirements (Keyword: While)

**MANDATORY**: Use for requirements active only during specific system states.

**Template**:
```text
While [precondition state], the [system name] shall [system response]
```

**When to Use**:
- Behaviors dependent on system state
- Conditional constraints
- Mode-specific requirements

**Examples**:
```text
✅ CORRECT: While the ATM has no card in the reader, the ATM shall display a prompt to insert a card
✅ CORRECT: While the system is in maintenance mode, the API shall reject all requests
✅ CORRECT: While battery level is below 10%, the device shall disable background sync
```

### 4. Optional Feature Requirements (Keyword: Where)

**MANDATORY**: Use for requirements applying only when specific features are included.

**Template**:
```text
Where [feature is included], the [system name] shall [system response]
```

**When to Use**:
- Platform-specific features
- Optional product configurations
- Feature flag implementations

**Examples**:
```text
✅ CORRECT: Where a sunroof is fitted, the control panel shall have a sunroof switch
✅ CORRECT: Where the premium tier is enabled, the application shall provide real-time analytics
✅ CORRECT: Where biometric authentication is available, the system shall offer fingerprint login
```

### 5. Unwanted Behavior Requirements (Keywords: If-Then)

**MANDATORY**: Use for requirements handling error conditions and undesirable situations.

**Template**:
```text
If [unwanted condition/trigger], then the [system name] shall [system response]
```

**When to Use**:
- Error handling requirements
- Exception cases
- Safety-critical responses to failures

**Examples**:
```text
✅ CORRECT: If the credit card number is invalid, then the payment system shall reject the transaction
✅ CORRECT: If memory allocation fails, then the application shall log the error and terminate gracefully
✅ CORRECT: If connection to the database is lost, then the service shall retry with exponential backoff
```

### 6. Complex Requirements (Multiple Keywords)

**RECOMMENDED**: Combine patterns for sophisticated behaviors requiring both preconditions and triggers.

**Template**:
```text
While [precondition], when [trigger], the [system name] shall [system response]
```

**Examples**:
```text
✅ CORRECT: While the aircraft is on the ground, when reverse thrust is selected, the engine shall provide reverse thrust
✅ CORRECT: While the user is authenticated, when a file upload completes, the system shall send a notification
✅ CORRECT: While in production mode, when an error occurs, the logger shall send alerts to the monitoring service
```

## Implementation

### Writing Requirements

1. **Identify Requirement Type**: Determine which EARS pattern fits your requirement
2. **Apply Template**: Use the appropriate keyword structure
3. **Verify Completeness**: Ensure system name and response are explicit
4. **Check Temporal Order**: Precondition → Trigger → System → Response

### Validation

- **Syntax Check**: Verify keywords appear in correct order
- **Ambiguity Test**: Ensure requirement has single, clear interpretation
- **Testability Check**: Confirm requirement is objectively verifiable
- **Completeness**: Validate all necessary context is captured

### Tooling Integration

- Use EARS templates in requirements management tools
- Create validation rules for keyword patterns
- Implement automated syntax checking
- Generate traceability matrices from structured requirements

## Benefits

1. **Precision**: Structured syntax eliminates ambiguous language
2. **Consistency**: Same temporal pattern across all requirement types
3. **Testability**: Clear triggers and responses enable verification
4. **Completeness**: Template structure ensures necessary context is captured
5. **Learnability**: Five simple patterns cover all requirement types
6. **Reduced Volatility**: Clear requirements minimize misinterpretation and rework
7. **Traceability**: Structured format improves automated parsing and linking

## Examples

### ✅ CORRECT: Well-Formed EARS Requirements

```markdown
## Authentication Requirements

REQ-001: The authentication service shall validate user credentials within 500ms

REQ-002: When a user submits login credentials, the system shall verify against the user database

REQ-003: While the user is not authenticated, the application shall display only public content

REQ-004: Where two-factor authentication is enabled, the system shall require a second verification step

REQ-005: If authentication fails three times, then the system shall lock the account for 15 minutes

REQ-006: While the user session is active, when the session timeout expires, the system shall redirect to the login page
```

### ❌ INCORRECT: Poorly-Formed Requirements

```markdown
❌ The system should probably handle errors gracefully
   Problem: Vague language ("should probably"), no explicit trigger or response

❌ When the button is clicked, do something with the data
   Problem: Ambiguous system name ("do something"), unclear response

❌ If error then retry or maybe log it
   Problem: Ambiguous response ("or maybe"), uncertain behavior

❌ The API might need to validate input in some cases
   Problem: Uncertain trigger ("might", "some cases"), vague scope

❌ While logged in, show the dashboard or profile
   Problem: Multiple responses without clear condition ("or")
```

### ✅ CORRECT: EARS Anti-Pattern Corrections

| ❌ Incorrect | ✅ EARS Correction | Pattern |
|--------------|-------------------|---------|
| The system should validate input | The input validator shall reject malformed requests | Ubiquitous |
| When error occurs, handle it | If a database connection fails, then the service shall retry up to 3 times | Unwanted |
| Display menu if user wants it | When the user clicks the menu button, the UI shall display the navigation menu | Event-Driven |
| Maybe show premium features | Where the premium subscription is active, the application shall enable advanced analytics | Optional |
| While running, do stuff | While the service is running, the health check endpoint shall return HTTP 200 | State-Driven |

### Complex Requirement Example

```markdown
## Automotive Safety Requirement

REQ-AUTO-042: While the vehicle speed exceeds 60 km/h, when the driver applies the brakes, the anti-lock braking system shall modulate brake pressure to prevent wheel lockup

**Breakdown**:
- Precondition: "While the vehicle speed exceeds 60 km/h"
- Trigger: "when the driver applies the brakes"
- System: "the anti-lock braking system"
- Response: "shall modulate brake pressure to prevent wheel lockup"
```

## Anti-Patterns to Avoid

### 1. Ambiguous Quantifiers

```markdown
❌ The system should usually respond quickly
✅ The API shall respond within 200 milliseconds for 95% of requests
```

### 2. Missing System Name

```markdown
❌ When the user logs in, display the dashboard
✅ When the user logs in, the web application shall display the dashboard
```

### 3. Multiple Unrelated Responses

```markdown
❌ The system shall validate input and send emails and log events
✅ REQ-001: The input validator shall check all user input against schema
✅ REQ-002: When validation passes, the notification service shall send a confirmation email
✅ REQ-003: The audit logger shall record all validation attempts
```

### 4. Vague Triggers

```markdown
❌ When appropriate, the system shall send alerts
✅ When CPU usage exceeds 80% for more than 5 minutes, the monitoring system shall send alerts to on-call engineers
```

### 5. Mixing Requirement Types

```markdown
❌ If the feature is enabled and the user clicks, maybe show the dialog while connected
✅ REQ-001: Where the advanced features toggle is enabled, the UI shall display the advanced settings button
✅ REQ-002: When the user clicks the advanced settings button, the application shall open the settings dialog
✅ REQ-003: While the network connection is active, the settings dialog shall display cloud sync options
```

## Migration from Unconstrained Requirements

### Step 1: Identify Implicit Structure

Read existing requirement and identify:
- Is there a precondition? (use "While" or "Where")
- Is there a trigger? (use "When" or "If")
- What is the system response? (explicit action)

### Step 2: Apply Appropriate Pattern

Map requirement to EARS pattern based on identified structure.

### Step 3: Refine for Precision

Remove ambiguous language, quantify where possible, make system name explicit.

### Example Migration

```markdown
Original (Unconstrained):
"The application should handle login attempts appropriately"

Analysis:
- Trigger: Login attempt (event-driven)
- System: Authentication service
- Response: Needs specification

EARS Refinement:
✅ REQ-AUTH-001: When a user submits login credentials, the authentication service shall verify credentials against the user database within 2 seconds

✅ REQ-AUTH-002: If credential verification fails, then the authentication service shall increment the failed attempt counter

✅ REQ-AUTH-003: If the failed attempt counter reaches 3, then the authentication service shall lock the account for 15 minutes
```

## Quality Checklist

Before finalizing any requirement, verify:

- [ ] Appropriate EARS keyword used (While/When/Where/If-Then/None)
- [ ] System name explicitly stated
- [ ] Response is specific and measurable
- [ ] No ambiguous language ("appropriate", "reasonable", "usually", "might")
- [ ] Testable as pass/fail
- [ ] Single responsibility (one behavior per requirement)
- [ ] Temporal order maintained (precondition → trigger → response)

## References

- [Alistair Mavin: EARS Official Site](https://alistairmavin.com/ears/)
- [Mavin et al., "EARS (Easy Approach to Requirements Syntax)", 2009 IEEE International Requirements Engineering Conference](https://doi.org/10.1109/RE.2009.9)
- [NASA Systems Engineering Handbook: Requirements Best Practices](https://www.nasa.gov/reference/systems-engineering-handbook/)
- [INCOSE Guide to Writing Requirements](https://www.incose.org/)
