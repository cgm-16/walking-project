import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const deleteAllDocuments = functions.pubsub
  .schedule("0 4 * * 1")
  .onRun((context) => {
    const db = admin.firestore();
    const scoreboardRef = db.collection("scoreboard");

    scoreboardRef
      .get()
      .then((snapshot) => {
        const batch = db.batch();
        snapshot.forEach((doc) => {
          batch.delete(doc.ref);
        });
        return batch.commit();
      })
      .then(() => {
        return null;
      })
      .catch((err) => {
        return null;
      });
  });

export const showRankingPercentage = functions.https.onCall(async (req) => {
  const db = admin.firestore();
  const scoreboardRef = db.collection("scoreboard");
  const uid = req.data.uid as number;
  try {
    const snapshot = await scoreboardRef.orderBy("score", "desc").get();
    const sortedData: any[] = [];
    snapshot.forEach((doc) => sortedData.push(doc.data()));
    const rank = sortedData.findIndex((item) => item.uid === uid) + 1;
    const perc = Math.round((rank * 100) / sortedData.length);
    if (rank > 0) {
      return {perc};
    } else {
      throw new functions.https.HttpsError(
        "not-found",
        "Score not found in the collection"
      );
    }
  } catch (error) {
    console.error("Error checking rank:", error);
    throw new functions.https.HttpsError("internal", "Error checking rank");
  }
});
