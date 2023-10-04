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


### For You Algorithm

Uses Shaped.AI

Data is streamed from firestore to bigquery. The video records, and the user viewedVideos collections. (2 different extensions to 2 different biquery tables). Access is then grated to Shaped.AI to read from these BigQuery tables and generate a dataset. That dataset is then fed into a shaped ai model, which can be queried for recommendations.

Giving the shaped ai access to big table - service account - client-bigquery-153@friendly-plane-323816.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding <YOUR_PROJECT> \
--member='serviceAccount:<OUR_SERVICE_ACCOUNT>' \
--role='roles/bigquery.dataViewer'

gcloud projects add-iam-policy-binding <YOUR_PROJECT> \
--member='serviceAccount:<OUR_SERVICE_ACCOUNT>' \
--role='roles/bigquery.jobUser'

gcloud projects add-iam-policy-binding <YOUR_PROJECT> \
--member='serviceAccount:<OUR_SERVICE_ACCOUNT>' \
--role='roles/bigquery.readSessionUser'
