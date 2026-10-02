# GoBison

### Product Vision

GoBison is a carpooling app for University of Manitoba students that helps students find and coordinate rides to and from campus. The app connects students who need a ride with students who are already driving to the university, allowing them to share trips and transportation costs.

The product addresses the difficulty many students face when commuting to campus, especially students who live far from the university or have limited access to convenient transportation. It also gives drivers an easy way to find other students travelling along similar routes and share the cost of their trips.

The goal of GoBison is to make commuting to the University of Manitoba more convenient, affordable, and accessible by creating a carpooling platform specifically for the university community.

### Invented Customer / Stakeholder Context

Our primary users are University of Manitoba students who commute to campus. This includes both **drivers** who regularly travel to the university by car and **passengers** who need transportation to and from campus.

We imagine the University of Manitoba Student Union (UMSU) as a potential stakeholder interested in improving transportation options for students. The university community currently has students travelling to campus from many different areas of Winnipeg, often along similar routes. However, there is no dedicated platform for students to easily find and coordinate carpools with other UManitoba students.

For example, a student living in Transcona may drive to campus several days a week while another student living nearby needs a ride to the university. A student without a car could search for available rides that match their schedule and location. The two students could then coordinate the trip through the app. This creates an opportunity for students to reduce transportation costs, make commuting more convenient, and connect with other members of the University of Manitoba community.

### Technology Decisions

Our initial technology stack is Flutter with Dart for the frontend, Java for the backend, and PostgreSQL for the database.

#### Frontend: Flutter and Dart

We plan to use Flutter with Dart to build the user interface, including login, ride posts, maps, and chat. For our group project, team members can work on different screens and share reusable UI components. This can reduce repeated work and help keep the app's design consistent.

#### Backend: Java

We plan to use Java for the backend. It will handle user accounts, ride requests, and chat rules. Java's classes and interfaces can help us organize these features into separate parts. This can make the code easier for team members to understand, test, and maintain.

#### Database: PostgreSQL

We plan to use PostgreSQL to store users, ride posts, ride agreements, messages, and ratings. This data has clear relationships. For example, each ride post belongs to a user. PostgreSQL uses tables and supports foreign keys to connect related records. This helps us keep these links valid when data is added or changed.

These are our initial choices. We may update them as we learn more about the project.


### Architecture
![Architecture diagram](https://github.com/popcorn9499/future-problems/blob/master/docs/process-docs/architecture_sprint0.png)
