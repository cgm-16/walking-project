import * as admin from "firebase-admin";
import { getMessaging, Message, Notification } from "firebase-admin/messaging";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { setGlobalOptions } from "firebase-functions/v2/options";
import { Firestore, WriteBatch } from "firebase-admin/firestore";

admin.initializeApp();

// Options for Firebase
setGlobalOptions({ region: "asia-northeast3" });

// Types
type EmoteDict = Record<keyof typeof NotificationEmotes, string>;

// Enums
enum PushTextString {
  FIRSTMORNING = "1등을 유지 중이네요 굿~~",
  FIRSTEVENING = "여전히 1등을 유지 중이네요 굿~~",
  SAMEMORNING = "같은 순위를 유지중이네요! 오늘도 화이팅!",
  SAMEEVENING = "같은 순위를 유지중이네요! 오늘도 화이팅!",
  DIFFPREMORNING = "어제보다 순위가",
  DIFFPREEVENING = "아침보다 순위가",
  DIFFSUFHIGHER = "계단 상승했어요! 굿~~",
  DIFFSUFLOWER = "계단 하락했어요! ㅠㅠ 분발하세여",
  NOPASTRECORDMORNING = "어제 기록이 없네요 ㅠㅠ 분발하세여",
  NOPASTRECORDEVENING = "아침 기록이 없네요 ㅠㅠ 분발하세여",
  CANNOTCOMPARE = "다음 알림 부터는 순위를 알려줄 거에요!",
}

enum Emotes {
  HEARTEYES,
  TAUNTFACE,
  WOWFACE,
}

enum NotificationEmotes {
  HEARTEYES,
  TAUNTFACE,
  WOWFACE,
  SUNGLASSES,
}

// Constants
const EXPIRATION_TIME = 1000 * 60 * 60 * 24 * 60;
const db = admin.firestore();
const messaging = getMessaging();
const emoteDict: EmoteDict = {
  HEARTEYES: "\uD83D\uDE0D",
  TAUNTFACE: "\uD83D\uDE1C",
  WOWFACE: "\uD83D\uDE32",
  SUNGLASSES: "\uD83D\uDE0E",
};

// Firebase Functions
// Function to delete all docs every monday 4am
export const deletealldocuments = onSchedule("0 19 * * 0", async () => {
  const scoreboardRef = db.collection("scoreboard");
  const batch = db.batch();

  try {
    const snap = await scoreboardRef.get();
    snap.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();
  } catch (err) {
    console.error("Error deleting leaderboard:", err);
    throw new HttpsError("internal", "Error in deleteAllDocuments");
  }
});

// Function to show ranking percentage
// req.data.uuid: the uuid of requester
export const showrankingpercentage = onCall(async (req) => {
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

// Function to send notification on 11:30am everyday
// copies the contents of scoreboard to lastboard at execution
export const sendmornfcm = onSchedule("30 2 * * *", async () => {
  const fcmtokensRef = db.collection("fcmtokens");
  const scoreboardRef = db.collection("scoreboard");
  const lastboardRef = db.collection("lastboard");

  try {
    const fcmsnap = await fcmtokensRef.get();
    const scoresnap = await scoreboardRef.orderBy("score", "desc").get();
    const lastsnap = await lastboardRef.orderBy("score", "desc").get();
    let batch = db.batch();

    for (const doc of fcmsnap.docs) {
      const uuid = doc.get("uuid") as number;

      const rank =
        scoresnap.docs.findIndex(
          (item) => (item.get("uuid") as number) === uuid
        ) + 1;
      const lastRank =
        lastsnap.docs.findIndex(
          (item) => (item.get("uuid") as number) === uuid
        ) + 1;

      const message: Message = {
        token: doc.get("token") as string,
      };

      if (lastRank === 0) {
        message.notification = mornNoti(PushTextString.CANNOTCOMPARE);
      } else if (rank === 0) {
        message.notification = mornNoti(PushTextString.NOPASTRECORDMORNING);
      } else if (rank === 1 && lastRank === 1) {
        message.notification = mornNoti(PushTextString.FIRSTMORNING);
      } else if (rank !== 1 && rank < lastRank) {
        message.notification = mornNoti(
          `${PushTextString.DIFFPREMORNING} ${lastRank - rank}${
            PushTextString.DIFFSUFHIGHER
          }`
        );
      } else if (rank !== 1 && rank > lastRank) {
        message.notification = mornNoti(
          `${PushTextString.DIFFPREMORNING} ${rank - lastRank}${
            PushTextString.DIFFSUFLOWER
          }`
        );
      } else {
        message.notification = mornNoti(PushTextString.SAMEMORNING);
      }

      try {
        await messaging.send(message);
      } catch (err) {
        if (err instanceof Error) {
          console.error("Error sending notification", err);
        } else {
          console.error("Error sending notification", String(err));
        }
      }
    }

    let count = 0;
    const docs = lastsnap.docs;
    for (const doc of docs) {
      if (count <= 490) {
        batch.delete(doc.ref);
        count += 1;
      } else {
        count = 0;
        batch = await commit(batch, db);
      }
    }
    for (const doc of scoresnap.docs) {
      if (count <= 490) {
        batch.create(lastboardRef.doc(doc.get("uuid") as string), {
          uuid: doc.get("uuid") as string,
          score: doc.get("score") as string,
        });
        count += 1;
      } else {
        count = 0;
        batch = await commit(batch, db);
      }
    }
    await batch.commit();
  } catch (error) {
    console.error("Error sendmornfcm:", error);
    throw new HttpsError("internal", "Error in sendmornfcm");
  }
});

// Function to send notification on 5:30pm everyday
// copies the contents of scoreboard to lastboard at execution
export const sendevenfcm = onSchedule("30 8 * * *", async () => {
  const fcmtokensRef = db.collection("fcmtokens");
  const scoreboardRef = db.collection("scoreboard");
  const lastboardRef = db.collection("lastboard");

  try {
    const fcmsnap = await fcmtokensRef.get();
    const scoresnap = await scoreboardRef.orderBy("score", "desc").get();
    const lastsnap = await lastboardRef.orderBy("score", "desc").get();
    let batch = db.batch();

    for (const doc of fcmsnap.docs) {
      const uuid = doc.get("uuid") as number;

      const rank =
        scoresnap.docs.findIndex(
          (item) => (item.get("uuid") as number) === uuid
        ) + 1;
      const lastRank =
        lastsnap.docs.findIndex(
          (item) => (item.get("uuid") as number) === uuid
        ) + 1;

      const message: Message = {
        token: doc.get("token") as string,
      };

      if (lastRank === 0) {
        message.notification = evenNoti(PushTextString.CANNOTCOMPARE);
      } else if (rank === 0) {
        message.notification = evenNoti(PushTextString.NOPASTRECORDEVENING);
      } else if (rank === 1 && lastRank === 1) {
        message.notification = evenNoti(PushTextString.FIRSTEVENING);
      } else if (rank !== 1 && rank < lastRank) {
        message.notification = evenNoti(
          `${PushTextString.DIFFPREEVENING} ${lastRank - rank}${
            PushTextString.DIFFSUFHIGHER
          }`
        );
      } else if (rank !== 1 && rank > lastRank) {
        message.notification = evenNoti(
          `${PushTextString.DIFFPREEVENING} ${rank - lastRank}${
            PushTextString.DIFFSUFLOWER
          }`
        );
      } else {
        message.notification = evenNoti(PushTextString.SAMEEVENING);
      }

      try {
        await messaging.send(message);
      } catch (err) {
        if (err instanceof Error) {
          console.error("Error sending notification", err);
        } else {
          console.error("Error sending notification", String(err));
        }
      }
    }

    let count = 0;
    const docs = lastsnap.docs;
    for (const doc of docs) {
      if (count <= 490) {
        batch.delete(doc.ref);
        count += 1;
      } else {
        count = 0;
        batch = await commit(batch, db);
      }
    }
    for (const doc of scoresnap.docs) {
      if (count <= 490) {
        batch.create(lastboardRef.doc(doc.get("uuid") as string), {
          uuid: doc.get("uuid") as string,
          score: doc.get("score") as string,
        });
        count += 1;
      } else {
        count = 0;
        batch = await commit(batch, db);
      }
    }
    await batch.commit();
  } catch (error) {
    console.error("Error sendevenfcm:", error);
    throw new HttpsError("internal", "Error in sendevenfcm");
  }
});

export const prunetokens = onSchedule("every 24 hours", async () => {
  const staleTokensResult = await db
    .collection("fcmtokens")
    .where("timestamp", "<", Date.now() - EXPIRATION_TIME)
    .get();
  // Delete devices with stale tokens
  staleTokensResult.forEach((doc) => {
    doc.ref.delete();
  });
});

// Function to request sending emotes to other users
// req.data - .uuid: the uuid of the requester
//            .emote: the type of emote to send
//            .target: the uuid of the target - for token
export const sendemote = onCall(async (req) => {
  const uuid = req.data.uuid as number;
  const emoteType = req.data.emote as keyof typeof Emotes;
  const target = req.data.target as number;

  const fcmtokensRef = db.collection("fcmtokens");
  const namelistRef = db.collection("namelist");
  const scoreboardRef = db.collection("scoreboard");

  try {
    const fcmtokensSnap = await fcmtokensRef.get();
    const namelistSnap = await namelistRef.get();
    const scoresnap = await scoreboardRef.orderBy("score", "desc").get();

    const token =
      (fcmtokensSnap.docs
        .find((item) => (item.get("uuid") as number) === target)
        ?.get("token") as string) ?? "";

    const fromName =
      (namelistSnap.docs
        .find((item) => (item.get("uuid") as number) === uuid)
        ?.get("name") as string) ?? "";
    const toName =
      (namelistSnap.docs
        .find((item) => (item.get("uuid") as number) === target)
        ?.get("name") as string) ?? "";

    const fromRank =
      scoresnap.docs.findIndex(
        (item) => (item.get("uuid") as number) === uuid
      ) + 1;
    const toRank =
      scoresnap.docs.findIndex(
        (item) => (item.get("uuid") as number) === target
      ) + 1;

    const message: Message = {
      token: token,
      notification: handleEmoteNotifications(
        emoteType,
        fromName,
        toName,
        fromRank,
        toRank
      ),
      data: { Emote: emoteType },
    };

    try {
      await messaging.send(message);
    } catch (err) {
      if (err instanceof Error) {
        console.error("Error sending notification", err);
      } else {
        console.error("Error sending notification", String(err));
      }
    }
  } catch (error) {
    console.error("Error sendemote:", error);
    throw new HttpsError("internal", "Error in sendemote");
  }
});

// Private functions
const mornNoti = (body: string): Notification => ({
  title: "점심 알림",
  body,
});

const evenNoti = (body: string): Notification => ({
  title: "저녁 알림",
  body,
});

const commit = async (
  batch: WriteBatch,
  db: Firestore
): Promise<admin.firestore.WriteBatch> => {
  try {
    await batch.commit();
  } catch (err) {
    if (err instanceof Error) {
      console.error("Error commiting writebatch", err);
      throw err;
    } else {
      console.error("Error commiting writebatch", String(err));
      throw err;
    }
  }
  return db.batch();
};

const handleEmoteNotifications = (
  emoteType: keyof typeof Emotes,
  fromName: string,
  toName: string,
  fromRank: number,
  toRank: number
): Notification => {
  switch (emoteType) {
    case "HEARTEYES":
      return {
        title: `${fromName} 님이 ${toName} 님에게 ${emoteDict[emoteType]}을 표시했어요.`,
        body: "걷기 마스터네요! 멋있어요!",
      };
    case "TAUNTFACE":
      if (fromRank < toRank || toRank === 0) {
        return {
          title: `${fromName} 님이 ${toName} 님에게 도발을 날렸어요.`,
          body: "아직 많이 부족하네요. 분발하세요!",
        };
      } else {
        return {
          title: `${fromName} 님이 ${toName} 님에게 도발을 날렸어요.`,
          body: `그정도면 금방 따라잡겠네요${emoteDict["SUNGLASSES"]}`,
        };
      }
    case "WOWFACE":
      if (fromRank < toRank || toRank === 0) {
        return {
          title: `${fromName} 님이 ${toName} 님에게 ${emoteDict[emoteType]}을 표시했어요.`,
          body: "점수를 많이 쌓았네요! 화이팅하세요!",
        };
      } else {
        return {
          title: `${fromName} 님이 ${toName} 님에게 ${emoteDict[emoteType]}을 표시했어요.`,
          body: "어메이징한 점수네요...",
        };
      }
  }
};
