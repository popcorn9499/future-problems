# Sprint 1

## Sprint Summary

This sprint, our team focused on building out our core features and implementing the majority of our project's functionality. We introduced the ability for users to edit their profiles, post ride requests and offers, chat in real-time with other users, view their dashboard summarizing all of their agreements, and browse nearby postings on a map. We also made sure to smooth out any outstanding issues from sprint 1, like minor issues with cookies and deployment.

## Completed Work

- Allow users to edit their profiles
- Dashboard showing users all of their current agreements and postings
- Users can now create ride requests and offers
- Implemented a map that displays all open ride offers and requests nearby
- Allow users to edit and delete their ride arrangements
- Allow users to delete their account
- Implemented live chat functionality for users to talk to eachother
- Added regression tests to our automated test suite
- Added linting to our CI pipeline

## Regression Testing

## Testing Status & Gaps

[![Backend Test Status](https://github.com/popcorn9499/future-problems/actions/workflows/backend-ci.yml/badge.svg)](https://github.com/popcorn9499/future-problems/actions/workflows/backend-ci.yml/)
[![Frontend Test Status](https://github.com/popcorn9499/future-problems/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/popcorn9499/future-problems/actions/workflows/flutter-ci.yml/)

The team currently uses a combination of unit, integration, and frontend widget tests to verify the functionality of our application, and all tests are run upon pushes and pull requests through our CI pipeline.

Our test methods have remained the same as outlined in [the testing status section of sprint1.md](../sprint1/sprint1.md), we have continued to use flutter widget tests, Junit 5, SpringBoot tools, and Mockito.

There are some testing gaps we are aware of, and would like to address in the next sprint. 
One gap in our frontend testing is the fact that the layouts are all tested at the same size, meaning we could miss overflow issues on smaller screen sizes. To fix this, we should add widget tests that run on smaller screen sizes next sprint.

We also currently have no tests that measure performance, so we do not yet know how the app and database will respond to higher amounts of traffic and queries. Our dashboard logic makes a lot of queries to the database, and could possibly return a very large amount of data to the frontend, so this could be a high-risk area. Next sprint, we will make sure to add tests to measure our app's performance.

Another area which might be considered a testing gap is accessbility. Flutter has built in tools for testing accessibility, which can measure how well the app is meeting accessbility guidelines for contrast, sizes, and labels. We have not used these tools this sprint, but would like to implement some tests using them during the next iteration.

In terms of coverage, our tests are covering a good percentage of code but we acknowledge that this only means the lines ran, and not that all inputs and behaviour are being thoroughly tested. We will aim to include a wider variety of test types and test more possible behaviours next sprint.

// TODO: ADD COVERAGE REPORTS

## CI/CD Status

## Live Deployment

## Cross-Team Testing

//TODO: LINK TO GITHUB ISSUE OPENED

## API Documentation

[Postman API documentation](https://www.postman.com/moreaboutrebekah-4859954/gobison/http-request/mmrfr8n/register-account?sideView=agentMode)

## Architecture

//TODO: LINK TO NEW ARCHITECTURE DIAGRAM

## Reflection & Risk

#### Sasha

There are some areas of uncertainty and technical risk in our project going into the final sprint. The ability to actually join other people’s postings is not implemented yet, nor is the ability for the creator of a posting to approve people joining. This is a possible risk going forward, as this implementation could affect surrounding features in ways we have not thought of yet and it’s arguably one of the most important workflows of our application. There is also some uncertainty surrounding how this might be implemented since there were some previously unconsidered rules and semantics surrounding this feature that came up this sprint, and it is also not fully decided how exactly we want to handle this functionality (e.g. should we have a notifications page, or should requests to join appear in the user's dashboard).

#### Work the team is proud of

Our team believes the frontend as a whole reflects the quality of this sprint well, as we feel that our user interface is intuitive, organized, and looks good visually. In particular, our map frontend, [found here](), is a good display of this sprint's quality as we feel it was a big undertaking to make this feature look clean while also being user-friendly and functional.

We also feel that our CI pipeline is a good reflection of the sprint's quality, as we believe it is well done and covers a variety of important tasks. This was selected partially due to how helpful it has been to all team members during development, and also due to how well it was set up.


