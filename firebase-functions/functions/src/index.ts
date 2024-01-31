import * as admin from "firebase-admin";
import { ApnsPayload, getMessaging, Message } from "firebase-admin/messaging";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { setGlobalOptions } from "firebase-functions/v2/options";

admin.initializeApp();

const db = admin.firestore();
const messaging = getMessaging();
const walkers = "walkers";
const silent: ApnsPayload = { aps: { contentAvailable: true } };

setGlobalOptions({ region: "asia-northeast3" });

// Function to delete all docs every monday 4am
export const deletealldocuments = onSchedule("0 4 * * 1", () => {
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

// Function to show ranking percentage
export const showrankingpercentage = onCall(async (req) => {
  const db = admin.firestore();
  const scoreboardRef = db.collection("scoreboard");
  const uuid = req.data.uuid as number;

  try {
    const snapshot = await scoreboardRef.orderBy("score", "desc").get();
    const rank =
      snapshot.docs.findIndex((item) => (item.get("uuid") as number) === uuid) +
      1;
    const perc = Math.round((rank * 100) / snapshot.size);
    const sum = snapshot.docs.reduce(
      (acc, cur) => (acc + cur.get("score")) as number,
      0
    );
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

// Function to send silent notification on 11:30am everyday
export const sendmornfcm = onSchedule("30 11 * * *", () => {
  const message: Message = {
    topic: walkers,
    apns: {
      payload: silent,
    },
    data: { noti: "morning" },
  };

  messaging
    .send(message)
    .then((res) => {
      console.log("Morning notification done", res);
    })
    .catch((err) => {
      console.log("Error sending notification", err);
    });
});

// Function to send silent notification on 5:30pm everyday
export const sendevenfcm = onSchedule("30 17 * * *", () => {
  const message: Message = {
    topic: walkers,
    apns: {
      payload: silent,
    },
    data: { noti: "evening" },
  };

  messaging
    .send(message)
    .then((res) => {
      console.log("Evening notification done", res);
    })
    .catch((err) => {
      console.log("Error sending notification", err);
    });
});
