# Vastly
A video-first podcast discovery platform.

### Ignore the following files:

- AuthorInfoView
- TextOverlayView
- VideoView
- TopTextView
- VideoHView

*These files have been left in case we revert to our previous UI.*

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
