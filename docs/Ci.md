# Continuous Integration

## Flutter CI

The workflow is defined in [flutter-ci.yml](../.github/workflows/flutter-ci.yml).

It checks the Flutter application in `gobison/`.

## Triggers

The workflow runs on every push and when a pull request is opened, reopened, or updated.

Push checks provide early feedback. Pull request checks help the team review changes before merging.

## Environment

The workflow runs on `ubuntu-latest` and uses Flutter `3.47.7` from the stable channel.

## Checks

1. Install dependencies with `flutter pub get`.
2. Analyze code with `flutter analyze --no-fatal-infos`.
3. Run tests and collect coverage with `flutter test --coverage`.
4. Generate an HTML coverage report and upload the coverage files.

## Analyzer policy

Info-level findings remain visible in the CI logs but do not fail the workflow. Warnings and errors still cause the analysis step to fail.

This allows the team to address existing style suggestions separately while keeping checks for warnings and errors active.

## Viewing results

Open the repository's Actions tab and select a Flutter CI run. Select the `flutter-check` job to view the logs for each step.

For a successful run, download the `flutter-coverage` artifact and extract the ZIP file. Open `html/index.html` in a browser to view the coverage report.

Coverage shows which recorded lines were executed by tests.
It does not prove that the code is correct or that every scenario has been tested.

## Backend CI

The workflow is defined in [backend-ci.yml](../.github/workflows/backend-ci.yml).

It builds and tests the Java backend in `backend/`.
It runs on pushes and when pull requests are opened, reopened, or updated.

### Test environment

The workflow runs on `ubuntu-latest` and uses Temurin Java `21`.

It starts a temporary PostgreSQL `17` database for testing.
The backend connects to this database using environment variables.

Hibernate uses `create-drop` to create tables when the application starts and drop them when it shuts down.

### Checks

1. Build and test the backend with `bash ./mvnw --batch-mode verify`.
2. Collect coverage with JaCoCo and generate reports during the `verify` phase.
3. Upload test reports from `backend/target/surefire-reports/`, even if tests fail.
4. Upload coverage reports from `backend/target/site/jacoco/` after a successful build.

### Viewing results

Open the repository's Actions tab and select a Backend CI run.
Select the `backend-check` job to view the logs for each step.

Download the `backend-test-reports` artifact and extract the ZIP file.
Open the `.txt` report to see the test count, failures, errors, and skipped tests.

For a successful run, download the `backend-coverage` artifact and extract the ZIP file. Open `index.html` in a browser to view the JaCoCo coverage report.

If the build fails before reports are generated, check the workflow logs.


## Flutter Integration Tests

The workflow is defined in [flutter-integration.yml](../.github/workflows/flutter-integration.yml).

It runs on every push and when a pull request is opened, reopened, or updated.

### Environment

The workflow runs on `ubuntu-latest` with Flutter `3.47.7`, Chrome, and a compatible ChromeDriver.

Chrome runs in headless mode in CI.

### Checks

1. Start ChromeDriver on port `4444`.
2. Run registration page and input validation tests.
3. Run registration response tests with a local mock backend.
4. Run email verification tests with a mock backend, covering incorrect codes and successful verification.

The response tests use a mock backend and do not verify the real backend,database ,or email delivery.