const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

// Cloud Function: Flag lifts for review when downvoted >40% after 100 views
exports.flagLift = functions.firestore
  .document('workouts/{workoutId}')
  .onUpdate((change, context) => {
    const newData = change.after.data();
    const previousData = change.before.data();
    
    // Only proceed if views or votes changed
    if (newData.views === previousData.views && 
        newData.upvotes === previousData.upvotes && 
        newData.downvotes === previousData.downvotes) {
      return null;
    }
    
    // Check if lift should be flagged for review
    if (newData.views >= 100) {
      const totalVotes = newData.upvotes + newData.downvotes;
      if (totalVotes > 0) {
        const downvoteRatio = newData.downvotes / totalVotes;
        if (downvoteRatio > 0.4) {
          return change.after.ref.update({ 
            status: 'pending',
            flaggedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      }
    }
    
    return null;
  });

// Cloud Function: Update workout vote counts when rating is created
exports.updateWorkoutVotes = functions.firestore
  .document('ratings/{ratingId}')
  .onCreate(async (snap, context) => {
    const rating = snap.data();
    const workoutRef = db.collection('workouts').doc(rating.workoutId);
    
    try {
      await db.runTransaction(async (transaction) => {
        const workoutDoc = await transaction.get(workoutRef);
        if (!workoutDoc.exists) {
          throw new Error('Workout not found');
        }
        
        const workout = workoutDoc.data();
        const updates = {};
        
        if (rating.value === 1) {
          updates.upvotes = (workout.upvotes || 0) + 1;
        } else if (rating.value === -1) {
          updates.downvotes = (workout.downvotes || 0) + 1;
        }
        
        transaction.update(workoutRef, updates);
      });
    } catch (error) {
      console.error('Error updating workout votes:', error);
    }
  });

// Cloud Function: Grant tokens when content receives positive engagement
exports.grantTokens = functions.firestore
  .document('ratings/{ratingId}')
  .onCreate(async (snap, context) => {
    const rating = snap.data();
    
    // Only grant tokens for upvotes
    if (rating.value !== 1) return null;
    
    try {
      // Get the workout to find the owner
      const workoutDoc = await db.collection('workouts').doc(rating.workoutId).get();
      if (!workoutDoc.exists) return null;
      
      const workout = workoutDoc.data();
      const userRef = db.collection('users').doc(workout.userId);
      
      // Grant 10 tokens for upvote
      await userRef.update({
        tokens: admin.firestore.FieldValue.increment(10),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
    } catch (error) {
      console.error('Error granting tokens:', error);
    }
  });

// Cloud Function: Weekly leaderboard snapshot (runs every Sunday at midnight)
exports.weeklyLeaderboardSnapshot = functions.pubsub
  .schedule('0 0 * * 0')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    try {
      // Get all users ordered by tokens
      const usersSnapshot = await db.collection('users')
        .orderBy('tokens', 'desc')
        .limit(100)
        .get();
      
      const leaderboardEntries = [];
      let rank = 1;
      
      usersSnapshot.forEach(doc => {
        const user = doc.data();
        leaderboardEntries.push({
          userId: doc.id,
          userName: user.name,
          team: user.team,
          tokens: user.tokens,
          rank: rank++
        });
      });
      
      // Store weekly snapshot
      await db.collection('leaderboards').doc('weekly').set({
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        entries: leaderboardEntries
      });
      
      // Reset weekly counters (if you have them)
      // This is where you'd reset weekly-specific counters
      
      console.log(`Weekly leaderboard snapshot created with ${leaderboardEntries.length} entries`);
      
    } catch (error) {
      console.error('Error creating weekly leaderboard snapshot:', error);
    }
  });

// Cloud Function: Update gym champion when new high lift is uploaded
exports.updateGymChampion = functions.firestore
  .document('workouts/{workoutId}')
  .onCreate(async (snap, context) => {
    const workout = snap.data();
    
    // Only proceed if workout has a gym and is published
    if (!workout.gymId || workout.status !== 'published') return null;
    
    try {
      const gymRef = db.collection('gyms').doc(workout.gymId);
      
      await db.runTransaction(async (transaction) => {
        const gymDoc = await transaction.get(gymRef);
        if (!gymDoc.exists) return null;
        
        const gym = gymDoc.data();
        const updates = {};
        
        // Check if this lift is a new record for the gym
        if (workout.liftType === 'squat') {
          if (!gym.bestSquat || workout.weight > gym.bestSquat.weight) {
            updates.bestSquat = {
              workoutId: workout.id,
              userId: workout.userId,
              userName: workout.userName || 'Unknown User',
              weight: workout.weight,
              timestamp: workout.createdAt
            };
          }
        } else if (workout.liftType === 'bench') {
          if (!gym.bestBench || workout.weight > gym.bestBench.weight) {
            updates.bestBench = {
              workoutId: workout.id,
              userId: workout.userId,
              userName: workout.userName || 'Unknown User',
              weight: workout.weight,
              timestamp: workout.createdAt
            };
          }
        } else if (workout.liftType === 'deadlift') {
          if (!gym.bestDeadlift || workout.weight > gym.bestDeadlift.weight) {
            updates.bestDeadlift = {
              workoutId: workout.id,
              userId: workout.userId,
              userName: workout.userName || 'Unknown User',
              weight: workout.weight,
              timestamp: workout.createdAt
            };
          }
        }
        
        if (Object.keys(updates).length > 0) {
          transaction.update(gymRef, updates);
        }
      });
      
    } catch (error) {
      console.error('Error updating gym champion:', error);
    }
  });

// Cloud Function: Notify admins when new report is created
exports.notifyAdminsOfReport = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap, context) => {
    const report = snap.data();
    
    try {
      // Get all admin users
      const adminUsersSnapshot = await db.collection('users')
        .where('isCoach', '==', true)
        .get();
      
      // Here you would implement notification logic
      // For now, we'll just log it
      console.log(`New report created: ${report.type} - ${report.reason}`);
      console.log(`Target ID: ${report.targetID}, Reporter: ${report.reporterID}`);
      
      // In a real implementation, you might:
      // - Send push notifications to admin devices
      // - Send emails to admin users
      // - Create admin dashboard alerts
      
    } catch (error) {
      console.error('Error notifying admins of report:', error);
    }
  });

