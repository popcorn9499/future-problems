# GoBison

### Product Vision

GoBison is a carpooling app for University of Manitoba students that helps students find and coordinate rides to and from campus. The app connects students who need a ride with students who are already driving to the university, allowing them to share trips and transportation costs.

The product addresses the difficulty many students face when commuting to campus, especially students who live far from the university or have limited access to convenient transportation. It also gives drivers an easy way to find other students travelling along similar routes and share the cost of their trips.

The goal of GoBison is to make commuting to the University of Manitoba more convenient, affordable, and accessible by creating a carpooling platform specifically for the university community.

### Invented Customer / Stakeholder Context

Our primary users are University of Manitoba students who commute to campus. This includes both **drivers** who regularly travel to the university by car and **passengers** who need transportation to and from campus.

We imagine the University of Manitoba Student Union (UMSU) as a potential stakeholder interested in improving transportation options for students. The university community currently has students travelling to campus from many different areas of Winnipeg, often along similar routes. However, there is no dedicated platform for students to easily find and coordinate carpools with other UManitoba students.

For example, a student living in Transcona may drive to campus several days a week while another student living nearby needs a ride to the university. A student without a car could search for available rides that match their schedule and location. The two students could then coordinate the trip through the app. This creates an opportunity for students to reduce transportation costs, make commuting more convenient, and connect with other members of the University of Manitoba community.

### Core Features
- [Account Creation](https://github.com/popcorn9499/future-problems/issues/2)
- [User Authentication](https://github.com/popcorn9499/future-problems/issues/3)
- [Post Ride Request](https://github.com/popcorn9499/future-problems/issues/4)
- [View Map of Ride Requests](https://github.com/popcorn9499/future-problems/issues/5)
- [User Dashboard of Accepted Requests](https://github.com/popcorn9499/future-problems/issues/6)
- [Live Chat](https://github.com/popcorn9499/future-problems/issues/7)
- [User Ratings](https://github.com/popcorn9499/future-problems/issues/8)

### Stretch Goal Features
- [Report Users](https://github.com/popcorn9499/future-problems/issues/9)
- [Recommendations](https://github.com/popcorn9499/future-problems/issues/10)

### Technology Decisions

Our initial technology stack is Flutter with Dart for the frontend, Java for the backend, and PostgreSQL for the database.

#### Frontend: Flutter and Dart

We plan to use Flutter with Dart to build the user interface, including login, ride posts, maps, and chat. We chose to use Flutter as it supports both desktop and mobile applications.

#### Backend: Java

We plan to use Java for the backend. It will handle user accounts, ride requests, and chat rules. Java's classes and interfaces can help us organize these features into separate parts. Our team has the most experience with Java which will help us to understand, test, and maintain the code throughout the course of the project.

#### Database: PostgreSQL

We plan to use PostgreSQL to store users, ride posts, ride agreements, messages, and ratings. This data has clear relationships. For example, each ride post belongs to a user. PostgreSQL uses tables and supports foreign keys to connect related records. This helps us keep these links valid when data is added or changed.

These are our initial choices. We may update them as we learn more about the project.

### Non-Functional Expectations
#### Performance
- Login and registration requests should complete within 5 seconds under normal load
- Ride requests should be processed promptly
- GoBison should support multiple users logging in and requesting rides simultaneously
#### Reliability
- The application should handle errors without crashing
- Ride bookings should not be duplicated if a user accidentally submits a request twice
- Booking and cancellation statuses should remain consistent between riders and drivers
#### Security
- Passwords must be stored securely, never as plain text
- Users should only access information they are authorized to view
- Personal information, contact details, and location data should be protected
#### Accessibility
- Riders should be able to request a ride with a clear, straightforward workflow
- Drivers should easily view and accept or decline ride requests
- Error messages should explain what went wrong and how to fix it
#### Availability
- If GoBison becomes temporarily unavailable, users should receive clear feedback when attempting to access its services

### Architecture
![Architecture diagram](https://github.com/popcorn9499/future-problems/blob/master/docs/process-docs/architecture_sprint0.png)

### Presentation
[Presentation](https://canva.link/d1k25x9tslqee8g)
