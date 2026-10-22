# Sprint 1

## Sprint Summary
For this sprint, our team focused on implementing the core account management features. Log in, account creation, and user verification features have been implemented end to end and backend infrastructure to support the application has been established.

## Completed Work
- Account creation
- Login
- Account verification
- Database integration
- Basic CI/CD pipeline

## Testing Status
The team currently uses a combination of unit, integration, and frontend widget tests to verify the functionality of our application.


**Frontend Testing:** Flutter widget tests verify login and registration form validation, including required fields, UMNetID formatting, password length, and acceptance of valid input.

**Unit Testing:** We use JUnit 5 to test the User domain model and EmailService. These tests cover object initialization, getters and setters, email message contents, and SMTP failure handling. We also test UserRepositoryImpl to verify repository behaviour and mapping between domain objects and persistence entities.

**Integration Testing:** EmailVerificationServiceIntegrationTest tests interactions between the verification service, repository, and PostgreSQL database.

**API and Security Testing:** Using Spring Boot's @WebMvcTest and MockMvc, we test the email-verification REST endpoint, including successful responses, authentication requirements, malformed requests, expected error responses, and handling of persistence failures without exposing internal details.

**Mocking/Test Utilities:** We use Mockito to mock the email service and verify interactions without sending real emails.

**Coverage and Evidence:** Our CI pipeline generates coverage reports, allowing us to identify under-tested areas without targeting a specific coverage percentage.


The backend uses JUnit and Spring Boot's testing framework.

The frontend uses Flutter's flutter_test package to perform widget tests. 

[Testing documentation]()

[Coverage report]()

## CI Status
For this sprint, we have implemented a basic CI pipeline. The workflow will run upon pushes, creation/reopening of pull requests, and updates to pull requests. 

The pipeline will do the following:
- install dependencies
- analyze code
- run tests and collect coverage
- generate coverage report


[CI documentation](docs/ci.md)

## API Documentation
[Postman API documentation](https://www.postman.com/moreaboutrebekah-4859954/gobison/http-request/mmrfr8n/register-account?sideView=agentMode)

## Architecture
[Sprint 1 architecture diagram]()

## Deployment
[Deployment URL]()

[Setup/run documentation]()

## Reflection

## Known Issues