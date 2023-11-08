import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { setGlobalOptions } from "firebase-functions/v2/options";

admin.initializeApp();

setGlobalOptions({ region: "asia-northeast3" });

export const deletealldocuments = onSchedule("0 4 * * 1", () => {
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
      console.error("Error deleting leaderboard:", err);
      throw new HttpsError("internal", "Error in deleteAllDocuments");
    });
});

export const showrankingpercentage = onCall(async (req) => {
  const db = admin.firestore();
  const scoreboardRef = db.collection("scoreboard");
  const uuid = req.data.uuid as number;

  try {
    const snapshot = await scoreboardRef.orderBy("score", "desc").get();
    const rank =
      snapshot.docs.findIndex(
        (item) => (item.get("uuid") as number) === uuid) + 1;
    const perc = Math.round((rank * 100) / snapshot.size);
    const sum = snapshot.docs.reduce(
      (acc, cur) => acc + cur.get("score") as number, 0);
    const avg = Math.trunc(sum / snapshot.size);
    if (rank > 0) {
      return { perc, avg };
    } else {
      throw new HttpsError("not-found", "Perc not found");
    }
  } catch (error) {
    console.error("Error checking rank:", error);
    throw new HttpsError("internal", "Error in showRankingPerc");
  }
});
