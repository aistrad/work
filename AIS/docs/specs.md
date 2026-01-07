# Output all documents in Simplified Chinese
# Project Context Understanding Requirements

## Mandatory Project Context Analysis

**BEFORE starting any specification phase or programming task, the model MUST:**

### 1. Project Discovery and Analysis
- **MANDATORY**: Thoroughly read and understand ALL projects in the  `~/work/AIS-v1`, `~/work/financial_analysis`directory before beginning spec phase or programming process
- **Systematic Exploration**: Systematically traverse the `~/work/AIS-v1`, `~/work/financial_analysis` directory to understand existing project structures and architectures
- **Component Inventory**: Identify reusable components, libraries, utilities, and modules that can be leveraged
- **Pattern Recognition**: Recognize design patterns, coding standards, and architectural decisions used across projects
- **Dependency Mapping**: Understand inter-project dependencies and shared resources

### 2. Context Integration Strategy
- **Identify Reusable Elements**:
  - Common utility functions and helper modules
  - Shared data models and schemas
  - Existing API clients and service integrations
  - Configuration management patterns
  - Logging and monitoring implementations
  - Error handling strategies
  - Testing frameworks and utilities

- **Learn from Existing Solutions**:
  - Study similar feature implementations across projects
  - Understand proven architectural patterns in use
  - Identify best practices and conventions already established
  - Review existing documentation and design decisions
  - Analyze performance optimizations and scalability solutions

### 3. Context Application Requirements
- **During Requirements Phase**:
  - Reference similar features from existing projects
  - Align new requirements with established project patterns
  - Identify opportunities to extend existing functionality
  - Ensure consistency with overall system architecture

- **During Design Phase**:
  - Leverage proven design patterns from existing projects
  - Reuse architectural components where appropriate
  - Maintain consistency with established coding standards
  - Build upon existing infrastructure and frameworks

- **During Implementation Phase**:
  - Import and utilize existing modules and libraries
  - Follow established coding conventions and patterns
  - Integrate with existing logging and monitoring systems
  - Reuse test utilities and fixtures where applicable

### 4. Documentation of Context Usage
- **The model MUST document**:
  - Which existing components are being reused
  - What patterns or approaches are borrowed from other projects
  - How the new feature integrates with existing systems
  - Dependencies on other projects or shared resources

### 5. Continuous Context Awareness
- **Throughout development, maintain awareness of**:
  - Changes in related projects that might affect current work
  - New utilities or components that become available
  - Evolving best practices across the codebase
  - Opportunities for code consolidation and refactoring

---

# Specification Requirements Clarification Prompt

**Workflow Stage:** Requirements Gathering

```
### 1. Requirement Gathering

First, generate an initial set of requirements in EARS format based on the feature idea, then iterate with the user to refine them until they are complete and accurate.

Don't focus on code exploration in this phase. Instead, just focus on writing requirements which will later be turned into
a design.

**Core Principles:**

- The model MUST focus on core requirements and keep the project simple and concise
- The model MUST NOT add unnecessary features or complexity without explicit user request
- The model MUST ask the user for clarification when uncertain about requirements or scope
- The model MUST prioritize essential functionality over nice-to-have features
- The model MUST question any requirement that seems to add complexity without clear user value
- The model MUST ensure every program includes comprehensive logging mechanisms for debugging, monitoring, and audit purposes
- The model MUST ensure all code changes maintain strict consistency with the Detailed Execution Flow Design documentation

**Project Structure Principles:**

- The model MUST include comprehensive logging requirements in all specifications to ensure proper debugging, monitoring, and audit capabilities

**Constraints:**

- The model MUST create a '.claude/specs/{feature_name}/requirements.md' file if it doesn't already exist
- The model MUST generate an initial version of the requirements document based on the user's rough idea WITHOUT asking sequential questions first
- The model MUST format the initial requirements.md document with:
  - A clear introduction section that summarizes the feature
  - A hierarchical numbered list of requirements where each contains:
    - A user story in the format "As a [role], I want [feature], so that [benefit]"
    - A numbered list of acceptance criteria in EARS format (Easy Approach to Requirements Syntax)
  - **Mandatory logging requirements** that specify:
    - What events/actions must be logged
    - Log levels (DEBUG, INFO, WARN, ERROR, FATAL)
    - Log format and structure requirements
    - Log retention and rotation policies
    - Performance monitoring requirements
  - Example format:
[includes example format here]
- The model SHOULD consider edge cases, user experience, technical constraints, success criteria, and comprehensive logging requirements in the initial requirements
- The model MUST keep requirements focused on core functionality and avoid feature creep
- The model MUST explicitly ask the user about scope boundaries when requirements seem to expand beyond the core feature
- After updating the requirement document, the model MUST ask the user "Do the requirements look good? If so, we can move on to the design." using the 'userInput' tool.
- The 'userInput' tool MUST be used with the exact string 'spec-requirements-review' as the reason
- The model MUST make modifications to the requirements document if the user requests changes or does not explicitly approve
- The model MUST ask for explicit approval after every iteration of edits to the requirements document
- The model MUST NOT proceed to the design document until receiving clear approval (such as "yes", "approved", "looks good", etc.)
- The model MUST continue the feedback-revision cycle until explicit approval is received
- The model SHOULD suggest specific areas where the requirements might need clarification or expansion
- The model MAY ask targeted questions about specific aspects of the requirements that need clarification
- The model MAY suggest options when the user is unsure about a particular aspect
- The model MUST proceed to the design phase after the user accepts the requirements
```

# Specification Design Document Creation Prompt

**Workflow Stage:** Design Document Creation

```
### 2. Create Feature Design Document

After the user approves the Requirements, you should develop a comprehensive design document based on the feature requirements, conducting necessary research during the design process.
The design document should be based on the requirements document, so ensure it exists first.

**Core Principles:**

- The model MUST maintain project simplicity and avoid over-engineering
- The model MUST design for clean, organized directory structure
- The model MUST separate core code from temporary/test code using dedicated subdirectories
- The model MUST ensure all documentation stays synchronized with design decisions
- The model MUST ensure the copied AGENTS.md file from parent project is accessible and referenced as needed
- The model MUST design comprehensive logging architecture that supports debugging, monitoring, and audit requirements
- The model MUST create detailed execution flow design that serves as the authoritative reference for all code implementation and modifications

**Constraints:**

- The model MUST create a '.claude/specs/{feature_name}/design.md' file if it doesn't already exist
- The model MUST verify that AGENTS.md file has been copied from parent project to sub-project root directory
- The model MUST identify areas where research is needed based on the feature requirements
- The model MUST conduct research and build up context in the conversation thread
- The model SHOULD NOT create separate research files, but instead use the research as context for the design and implementation plan
- The model MUST summarize key findings that will inform the feature design
- The model SHOULD cite sources and include relevant links in the conversation
- The model MUST create a detailed design document at '.claude/specs/{feature_name}/design.md'
- The model MUST incorporate research findings directly into the design process
- The model MUST include the following sections in the design document:
  - Overview
  - Architecture
  - **Detailed Execution Flow Design** (step-by-step process flow with decision points)
  - Components and Interfaces
  - Data Models
  - **Directory Structure** (including separation of core code, tests, and temporary files)
  - **AGENTS.md Integration** (how the copied AGENTS.md file should be used in the project)
  - **Logging Architecture** (comprehensive logging design including levels, formats, storage, and monitoring)
  - Error Handling
  - Testing Strategy
  - **Documentation Synchronization Plan**
- The model MUST include a detailed execution flow section that maps out:
  - Step-by-step process flows for all major operations with explicit sequence numbers
  - Decision points and branching logic with clear conditions and outcomes
  - Error handling paths with specific error scenarios and recovery procedures
  - User interaction flows with detailed input/output specifications
  - Data flow between components with clear data transformation points
  - **Logging points and log levels for each operation step**
  - **Performance monitoring and metrics collection points**
  - **Code implementation checkpoints** that directly correspond to execution steps
  - **Version control integration** to track changes to execution flow design
- The model MUST design a clean directory structure that separates:
  - Core application code in main directories
  - Test code in dedicated test subdirectories (e.g., `/tests`, `/test-utils`)
  - Temporary/development code in dedicated subdirectories (e.g., `/temp`, `/dev-tools`, `/scripts`)
  - Documentation in organized documentation directories
  - The copied AGENTS.md file in the root directory for easy access
- The model SHOULD include diagrams or visual representations when appropriate (use Mermaid for diagrams if applicable)
- The model MUST ensure the design addresses all feature requirements identified during the clarification process
- The model SHOULD highlight design decisions and their rationales
- The model MUST prioritize simplicity and maintainability in all design decisions
- The model MUST create execution flow design with sufficient detail that any code modifications can be validated against it
- The model MUST ensure the execution flow design serves as the single source of truth for implementation logic
- The model MAY ask the user for input on specific technical decisions during the design process
- The model MUST ask the user to confirm scope when design seems to be expanding beyond core requirements
- After updating the design document, the model MUST ask the user "Does the design look good? If so, we can move on to the implementation plan." using the 'userInput' tool.
- The 'userInput' tool MUST be used with the exact string 'spec-design-review' as the reason
- The model MUST make modifications to the design document if the user requests changes or does not explicitly approve
- The model MUST ask for explicit approval after every iteration of edits to the design document
- The model MUST NOT proceed to the implementation plan until receiving clear approval (such as "yes", "approved", "looks good", etc.)
- The model MUST continue the feedback-revision cycle until explicit approval is received
- The model MUST incorporate all user feedback into the design document before proceeding
- The model MUST offer to return to feature requirements clarification if gaps are identified during design
```


# Specification Implementation Plan Prompt

**Workflow Stage:** Implementation Planning

```
### 3. Create Task List

After the user approves the Design, create an actionable implementation plan with a checklist of coding tasks based on the requirements and design.
The tasks document should be based on the design document, so ensure it exists first.

**Core Principles:**

- The model MUST keep implementation focused on core functionality only
- The model MUST ensure clean project organization with proper directory separation
- The model MUST include documentation update tasks to maintain synchronization
- The model MUST design debugging tasks that follow step-by-step real execution flow
- The model MUST ensure AGENTS.md file accessibility throughout implementation
- The model MUST implement comprehensive logging mechanisms as specified in the design document
- The model MUST ensure all code implementation strictly follows the Detailed Execution Flow Design and any code modifications must be accompanied by corresponding execution flow design updates
- The model MUST implement rigorous step-by-step testing that validates computational results against requirements, business logic, and algorithmic design while preventing memory overflow and other critical errors

**Constraints:**

- The model MUST create a '.claude/specs/{feature_name}/tasks.md' file if it doesn't already exist
- The model MUST ensure AGENTS.md file has been copied from parent project and is available in sub-project root
- The model MUST return to the design step if the user indicates any changes are needed to the design
- The model MUST return to the requirement step if the user indicates that we need additional requirements
- The model MUST create an implementation plan at '.claude/specs/{feature_name}/tasks.md'
- The model MUST include **mandatory code review and validation tasks** at the end of the implementation plan that verify:
  - Complete alignment between implemented code and design.md specifications
  - Full implementation of all designed features and functionalities
  - Consistency with Detailed Execution Flow Design at every step
  - Verification that all design decisions have been correctly implemented
  - Validation that no design requirements have been missed or incorrectly implemented
- The model MUST ensure the final validation phase includes:
  - **Comprehensive Design-to-Code Consistency Review**: Line-by-line verification that code implementation matches design.md specifications
  - **Feature Completeness Audit**: Systematic verification that every feature, component, and interface described in design.md has been fully implemented
  - **Execution Flow Validation**: Step-by-step verification that actual code execution follows the Detailed Execution Flow Design exactly
  - **Architecture Compliance Check**: Verification that implemented architecture matches the designed architecture
  - **Interface Implementation Verification**: Confirmation that all designed interfaces and APIs are correctly implemented
  - **Error Handling Completeness**: Verification that all error handling scenarios from design.md are properly implemented
  - **Performance Requirements Validation**: Confirmation that performance characteristics match design specifications
- The model MUST use the following specific instructions when creating the implementation plan:
  ```
  Convert the feature design into a series of prompts for a code-generation LLM that will implement each step in a test-driven manner. Prioritize best practices, incremental progress, and early testing, ensuring no big jumps in complexity at any stage. Make sure that each prompt builds on the previous prompts, and ends with wiring things together. There should be no hanging or orphaned code that isn't integrated into a previous step. Focus ONLY on tasks that involve writing, modifying, or testing code. Keep the implementation simple and focused on core requirements only.
  ```
- The model MUST format the implementation plan as a numbered checkbox list with a maximum of two levels of hierarchy:
  - Top-level items (like epics) should be used only when needed
  - Sub-tasks should be numbered with decimal notation (e.g., 1.1, 1.2, 2.1)
  - Each item must be a checkbox
  - Simple structure is preferred
- The model MUST ensure each task item includes:
  - A clear objective as the task description that involves writing, modifying, or testing code
  - Additional information as sub-bullets under the task
  - Specific references to requirements from the requirements document (referencing granular sub-requirements, not just user stories)
  - **Directory organization instructions** (where to place files, separation of core/test/temp code)
  - **AGENTS.md file usage instructions** where relevant
  - **Direct mapping to specific steps in the Detailed Execution Flow Design**
  - **Execution flow design update requirements** when code logic changes
- The model MUST include **final validation tasks** as the last section of the implementation plan that:
  - Systematically review every component against its design specification
  - Verify that all user stories and acceptance criteria are fully addressed by the implementation
  - Validate that the implemented system behaves exactly as designed in all scenarios
  - Generate a comprehensive validation report confirming design-to-implementation consistency
  - Require explicit sign-off that all design elements have been correctly implemented
- The model MUST include specific tasks for:
  - **Copying AGENTS.md from parent project to sub-project root directory** (if not already done)
  - Setting up proper directory structure as designed
  - **Implementing comprehensive logging system** with proper levels, formatting, and storage
  - **Creating logging configuration and management utilities**
  - Creating core functionality in main directories
  - **Validating each code implementation step against corresponding execution flow design steps**
  - Creating tests in dedicated test subdirectories
  - **Creating comprehensive computational validation tests** that verify:
    - Step-by-step calculation results against documented requirements
    - Business logic implementation against specified business rules
    - Algorithm implementation against algorithmic design specifications
    - Final output correctness against expected results
    - Memory usage patterns and overflow prevention
    - Edge case handling and boundary condition validation
  - **Creating logging tests to verify log output and levels**
  - Placing any temporary or development code in appropriate subdirectories
  - **Regular documentation updates** to keep docs synchronized with code changes
  - **Mandatory execution flow design updates** whenever code logic changes
  - **Step-by-step debugging procedures** that follow real execution flow without data simulation
  - **Verification that AGENTS.md file is properly accessible and used**
  - **Log monitoring and analysis setup for debugging and performance tracking**
  - **Cross-validation between actual code execution and documented execution flow design**
  - **Memory safety and performance monitoring tests** to prevent overflow and resource exhaustion
  - **Final code review and design consistency validation tasks** including:
    - Automated and manual verification that all code matches design.md specifications
    - Feature-by-feature implementation completeness audit
    - Cross-reference validation between actual code behavior and designed behavior
    - Identification and correction of any implementation gaps or inconsistencies
    - Final validation report generation documenting design-to-code alignment
- The model MUST ensure debugging tasks include:
  - **Mandatory verification that actual code execution matches each step in the Detailed Execution Flow Design**
  - **Step-by-step computational result validation** that verifies:
    - Each calculation step against documented requirements and expected outcomes
    - Business logic implementation against specified business rules and constraints
    - Algorithm execution against designed algorithmic specifications
    - Intermediate results accuracy at each computation stage
    - Final output correctness against defined success criteria
    - Memory allocation and deallocation patterns to prevent overflow
    - Resource usage monitoring to detect potential performance issues
  - Step-by-step execution flow verification from documentation to actual program behavior
  - Real data flow testing (no simulated data)
  - Verification of each component in the execution sequence
  - **Validation that all decision points and branching logic match the execution flow design**
  - **Verification that error handling paths follow the documented error handling procedures**
  - **Edge case and boundary condition testing** to ensure robust error handling
  - **Memory safety verification** including buffer overflow prevention and resource leak detection
  - Documentation-to-code consistency checks
  - Verification that AGENTS.md file integration works as designed
  - **Verification that logging works correctly at all levels and produces expected output**
  - **Log analysis and validation that logs provide sufficient debugging information**
  - **Performance monitoring verification through log analysis**
  - **Cross-reference testing between code behavior and execution flow design documentation**
  - **Identification and correction of any discrepancies between code and execution flow design**
  - **Regression testing after each modification** to ensure continued accuracy and stability
  - **Post-implementation design consistency validation** that includes:
    - Comprehensive comparison between implemented functionality and design.md specifications
    - Verification that all design decisions, architectural choices, and technical specifications are correctly reflected in code
    - Validation that no design elements have been omitted, modified, or incorrectly implemented
    - Final confirmation that the implemented system fully satisfies the original design intent
    - Documentation of any discrepancies found and their resolution
- The model MUST ensure that the implementation plan is a series of discrete, manageable coding steps
- The model MUST ensure each task references specific requirements from the requirement document
- The model MUST NOT include excessive implementation details that are already covered in the design document
- The model MUST assume that all context documents (feature requirements, design, AGENTS.md) will be available during implementation
- The model MUST ensure each step builds incrementally on previous steps
- The model SHOULD prioritize test-driven development where appropriate
- The model MUST ensure the plan covers all aspects of the design that can be implemented through code
- The model SHOULD sequence steps to validate core functionality early through code
- The model MUST ensure that all requirements are covered by the implementation tasks
- The model MUST offer to return to previous steps (requirements or design) if gaps are identified during implementation planning
- The model MUST ONLY include tasks that can be performed by a coding agent (writing code, creating tests, etc.)
- The model MUST NOT include tasks related to user testing, deployment, performance metrics gathering, or other non-coding activities
- The model MUST focus on code implementation tasks that can be executed within the development environment
- The model MUST ensure each task is actionable by a coding agent by following these guidelines:
  - Tasks should involve writing, modifying, or testing specific code components
  - Tasks should specify what files or components need to be created or modified
  - Tasks should be concrete enough that a coding agent can execute them without additional clarification
  - Tasks should focus on implementation details rather than high-level concepts
  - Tasks should be scoped to specific coding activities (e.g., "Implement X function" rather than "Support X feature")
  - **Tasks should specify exact directory placement for all files**
  - **Tasks should include documentation update requirements**
  - **Tasks should reference AGENTS.md file when configuration or context is needed**
  - **Tasks should include specific logging implementation requirements and verification steps**
  - **Tasks should specify log level usage and log message formatting standards**
  - **Tasks must include explicit reference to corresponding execution flow design steps**
  - **Tasks must specify validation criteria against execution flow design**
  - **Tasks must include execution flow design update requirements when code logic changes**
  - **Tasks must include step-by-step computational validation requirements** that specify:
    - Verification methods for calculation accuracy against requirements
    - Business logic validation against documented business rules
    - Algorithm implementation verification against design specifications
    - Final output validation against expected results and success criteria
    - Memory safety checks and overflow prevention measures
    - Performance monitoring and resource usage validation
    - Edge case and boundary condition testing procedures
- The model MUST explicitly avoid including the following types of non-coding tasks in the implementation plan:
  - User acceptance testing or user feedback gathering
  - Deployment to production or staging environments
  - Performance metrics gathering or analysis
  - Running the application to test end to end flows. We can however write automated tests to test the end to end from a user perspective.
  - User training or documentation creation
  - Business process changes or organizational changes
  - Marketing or communication activities
  - Any task that cannot be completed through writing, modifying, or testing code
- The model MUST question and confirm with the user any task that seems to add complexity beyond core requirements
- The model MUST prioritize tasks that deliver core functionality first, deferring any non-essential features
- After updating the tasks document, the model MUST ask the user "Do the tasks look good?" using the 'userInput' tool.
- The 'userInput' tool MUST be used with the exact string 'spec-tasks-review' as the reason
- The model MUST make modifications to the tasks document if the user requests changes or does not explicitly approve.
- The model MUST ask for explicit approval after every iteration of edits to the tasks document.
- The model MUST NOT consider the workflow complete until receiving clear approval (such as "yes", "approved", "looks good", etc.).
- The model MUST continue the feedback-revision cycle until explicit approval is received.
- The model MUST stop once the task document has been approved.

**This workflow is ONLY for creating design and planning artifacts. The actual implementation of the feature should be done through a separate workflow.**

- The model MUST NOT attempt to implement the feature as part of this workflow
- The model MUST clearly communicate to the user that this workflow is complete once the design and planning artifacts are created
- The model MUST inform the user that they can begin executing tasks by opening the tasks.md file.
- The model MUST ensure that AGENTS.md file has been properly copied and is available for use during implementation

**AGENTS.md File Management:**

- When creating a sub-project, the model MUST copy the parent project's AGENTS.md file to the sub-project root directory using:
  ```bash
  # Copy AGENTS.md from parent project
  cp ../AGENTS.md AGENTS.md
  
  # Or if parent project is in a different location
  cp ../../main-project/AGENTS.md AGENTS.md
  ```
- The model MUST verify the AGENTS.md file is accessible in the sub-project
- The model MUST reference the copied AGENTS.md file in design and implementation documents where relevant
- The model MUST include tasks to verify AGENTS.md file integration in the implementation plan

**Logging Mechanism Requirements:**

- The model MUST ensure every program includes a comprehensive logging system with the following characteristics:
  - **Log Levels**: Support for DEBUG, INFO, WARN, ERROR, and FATAL levels
  - **Structured Logging**: Consistent log format with timestamps, log levels, component names, and messages
  - **Configurable Output**: Support for console output, file output, and external logging services
  - **Performance Monitoring**: Log performance metrics and execution times for critical operations
  - **Error Tracking**: Detailed error logging with stack traces and context information
  - **Audit Trail**: Log important user actions and system state changes for debugging and compliance
- The model MUST design logging architecture that includes:
  - Log rotation and retention policies
  - Log level configuration (runtime adjustable when possible)
  - Structured log format (JSON recommended for machine readability)
  - Context-aware logging (include relevant operation context in log messages)
  - Performance impact minimization (async logging when appropriate)
- The model MUST include logging verification tasks that ensure:
  - All critical operations are properly logged
  - Log levels are used appropriately
  - Log messages are informative and actionable
  - Log format is consistent across the application
  - Log output can be easily parsed and analyzed
  - Performance impact of logging is acceptable

**Execution Flow Design Consistency Requirements:**

- The model MUST ensure that the Detailed Execution Flow Design serves as the authoritative specification for all code implementation
- The model MUST require that any code modification is accompanied by corresponding updates to the execution flow design
- The model MUST include validation tasks that verify actual program execution matches the documented execution flow design at every step
- The model MUST ensure that all decision points, branching logic, error handling paths, and data transformations in the code exactly match those specified in the execution flow design
- The model MUST include cross-validation tasks that compare:
  - Actual function call sequences vs. documented execution steps
  - Real error handling behavior vs. documented error handling paths
  - Actual data flow vs. documented data transformation points
  - Performance characteristics vs. documented performance expectations
- The model MUST require immediate synchronization between code changes and execution flow design updates
- The model MUST include regression testing that validates continued consistency between code and execution flow design after any modifications
- The model MUST treat discrepancies between code and execution flow design as critical errors that must be resolved before proceeding

**Comprehensive Code Testing and Validation Requirements:**

- The model MUST implement rigorous step-by-step testing procedures that validate all aspects of code functionality and correctness
- The model MUST ensure that all computational validation includes:
  - **Step-by-Step Calculation Verification**: Each mathematical operation and computation must be verified against documented requirements and expected mathematical outcomes
  - **Business Logic Validation**: All business rules, constraints, and logical operations must be validated against specified business requirements and real-world scenarios
  - **Algorithm Implementation Verification**: Algorithm execution must be validated against designed algorithmic specifications, including time complexity, space complexity, and correctness
  - **Intermediate Result Accuracy**: All intermediate calculation results must be verified for accuracy at each stage of computation
  - **Final Output Correctness**: Final program outputs must be validated against defined success criteria and expected results
  - **Edge Case and Boundary Testing**: All edge cases, boundary conditions, and limit scenarios must be thoroughly tested
- The model MUST implement comprehensive memory safety and resource management validation:
  - **Memory Overflow Prevention**: All memory allocations must be validated to prevent buffer overflows, stack overflows, and heap overflows
  - **Resource Leak Detection**: Memory leaks, file handle leaks, and other resource leaks must be detected and prevented
  - **Performance Monitoring**: Resource usage patterns, execution times, and memory consumption must be monitored and validated against performance requirements
  - **Scalability Testing**: Code must be tested with varying data sizes and loads to ensure scalability and prevent resource exhaustion
- The model MUST ensure that all testing procedures include:
  - **Real Data Testing**: Testing must use real data scenarios rather than simulated data whenever possible
  - **Stress Testing**: Code must be tested under high-load conditions to identify performance bottlenecks and resource limits
  - **Error Recovery Testing**: Error handling and recovery mechanisms must be thoroughly tested for robustness
  - **Regression Testing**: All modifications must be followed by comprehensive regression testing to ensure continued functionality
- The model MUST require that all test results are documented and validated against:
  - Original feature requirements and acceptance criteria
  - Business logic specifications and constraints
  - Algorithmic design and mathematical specifications
  - Performance and resource usage requirements
  - Security and safety requirements
- The model MUST treat any discrepancies between test results and specifications as critical errors that must be resolved before proceeding with implementation

## Language Preference
- **Primary conversation language**: Chinese (中文)
- **Documentation language**: English
- **Code comments**: English with Chinese explanations where needed

## Project Structure Requirements

### Directory Organization
Maintain a clean and organized project structure with dedicated subdirectories:

```
project-root/
├── .claude/           # AGENTS-specific files
│   └── specs/        # Feature specifications
├── src/              # Source code
│   ├── core/        # Core application logic
│   ├── models/      # Data models
│   ├── services/    # Business logic services
│   └── utils/       # Utility functions
├── config/           # Configuration files
│   ├── database.py  # Database configuration
│   └── settings.py  # Application settings
├── tests/            # Test files
│   ├── unit/       # Unit tests
│   ├── integration/ # Integration tests
│   └── fixtures/    # Test fixtures
├── logs/             # Log files
│   ├── app.log     # Application logs
│   └── error.log   # Error logs
├── docs/             # Documentation
├── scripts/          # Utility scripts
├── temp/             # Temporary files (gitignored)
└── AGENTS.md
```

## Development Environment

### Technology Stack
- **Language**: Python 3.11+
- **Database**: PostgreSQL 16+
- **Logging**: Python logging module with structured formatting

### Database Operations Requirements
- **MANDATORY**: All database operations MUST use transactions
- **Query Before Modify**: Always query database structure before field operations
- **Use parameterized queries** to prevent SQL injection
- **Connection pooling** for production environments

## AiScend Database Connection

### Connection Configuration
```python
# Database connection configuration
DATABASE_CONFIG = {
    "host": "localhost",
    "port": 8224,
    "database": "aiscend",
    "user": "postgres",
    "password": "Ak4_9lScd-69WX"
}

# Connection string
CONNECTION_STRING = "postgresql://postgres:Ak4_9lScd-69WX@localhost:8224/aiscend"

# psql command line connection
# PGPASSWORD="$PGPASSWORD" psql -h localhost -p 8224 -U postgres -d aiscend
```

### Database Best Practices
1. **Always inspect schema first**:
2. **Use transactions for data modifications**:
3. **Implement proper error handling and logging**

## Permission Settings

### 🟢 Green Zone (Auto-approve)
Operations that can be executed without confirmation:
- Git operations (status, diff, add, commit, push, pull)
- File read operations
- Creating new files in appropriate directories
- Running pytest tests
- Package installation (pip install, npm install)
- Database SELECT queries
- Log file operations
- Documentation updates

### 🟡 Yellow Zone (Confirm once)
Operations requiring initial confirmation:
- System commands (ls, ps, netstat)
- Network requests to known APIs
- Database CREATE TABLE, ALTER TABLE
- Creating new directories
- Environment variable modifications
- Configuration file changes

### 🔴 Red Zone (Always confirm)
High-risk operations requiring explicit confirmation every time:
- DELETE operations (files or database records)
- DROP TABLE, TRUNCATE operations
- System configuration changes
- Production database modifications
- Credential or secret modifications
- Recursive file operations
- Force push to git repositories

## Logging Configuration
### Log Levels and Usage
- **DEBUG**: Detailed debugging information
- **INFO**: General informational messages
- **WARNING**: Warning messages for potential issues
- **ERROR**: Error messages for recoverable errors
- **CRITICAL**: Critical errors that may cause system failure
