const functions = require("firebase-functions");
const admin = require('firebase-admin');
admin.initializeApp();

exports.deleteAllDocuments = functions.pubsub.schedule('0 4 * * 1').onRun((context) => {
    const db = admin.firestore();
    const scoreboardRef = db.collection('scoreboard');
    
    scoreboardRef.get().then((snapshot) => {
        const batch = db.batch();
        snapshot.forEach((doc) => {
            batch.delete(doc.ref);
        });
        return batch.commit();
    }).then(() => {
        return null;
    }).catch((err) => {
        return null;
    });
});
