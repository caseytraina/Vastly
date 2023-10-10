/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {logger} = require("firebase-functions");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
// The Firebase Admin SDK to access Firestore.
const {initializeApp} = require("firebase-admin/app");

initializeApp();

// Listens for new videos added to /videos/:documentId/title
// and saves a text field for converting to speech
// to /messages/:documentId/text
exports.writeTTSText = onDocumentCreated("/videos/{documentId}", (event) => {
  // Grab the current value of what was written to Firestore.
  const title = event.data.data().title;

  // Access the parameter `{documentId}` with `event.params`
  logger.log("Writing text field from title", event.params.documentId, title);

  const text = "Next up. " + title;

  // You must return a Promise when performing
  // asynchronous tasks inside a function
  // such as writing to Firestore.
  // Setting an 'text' field in Firestore document returns a Promise.
  return event.data.ref.set({text}, {merge: true});
});
