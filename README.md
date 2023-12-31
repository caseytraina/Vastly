# Vastly
A video-first podcast discovery platform.

### VideoStructure
Defines the structure of the videos, authors, and channels classes within the app.

### VideoViewModel
Connects to our backend (Firebase + ImageKit CDN) to query all of our videos and authors. This view model is initialized upon successful login.

### AuthViewModel
Handles user authentication through FirebaseAuth

### VideoObserver
A Child of VideoViewModel which controls video playing, pausing, creation, and deletion. This is an overarching view that controls the currently playing
video to avoid multiple videos playing at once.

### Analytics
Controls and creates functions for data collections.

*All other files are largely front-end with varying levels of small backend queries leftover from MVP*

### For You Algorithm

Uses Shaped.AI

Data is streamed from firestore to bigquery. The video records, and the user viewedVideos collections. (2 different extensions to 2 different biquery tables). Access is then grated to Shaped.AI to read from these BigQuery tables and generate a dataset. That dataset is then fed into a shaped ai model, which can be queried for recommendations.

### Functions

Firebase functions are stored in a node app in vastly-functions. They can be deployed with the firebase CLI - https://firebase.google.com/docs/functions/get-started?gen=2nd
