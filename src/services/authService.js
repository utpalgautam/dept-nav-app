// src/services/authService.js
import {
    createUserWithEmailAndPassword,
    signInWithEmailAndPassword,
    signOut,
    sendPasswordResetEmail
} from 'firebase/auth';
import { doc, setDoc, getDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from './firebaseConfig';

const USERS_COLLECTION = 'users';

/**
 * Registers a new admin user.
 * Creates the Firebase Auth account, then stores the user profile in Firestore
 * with userType='admin'.
 */
export const registerAdmin = async (name, email, password) => {
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;

    await setDoc(doc(db, USERS_COLLECTION, user.uid), {
        name,
        email,
        userType: 'admin',
        status: 'active',
        registrationDate: serverTimestamp(),
        lastLogin: serverTimestamp()
    });

    return user;
};

/**
 * Logs in an existing user. After Firebase Auth, fetches the Firestore record
 * and verifies userType === 'admin'. If not admin, signs out and throws.
 */
export const loginAdmin = async (email, password) => {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;

    const userDoc = await getDoc(doc(db, USERS_COLLECTION, user.uid));

    if (!userDoc.exists()) {
        await signOut(auth);
        throw new Error('No account record found. Please contact your administrator.');
    }

    const userData = userDoc.data();
    if (userData.userType !== 'admin') {
        await signOut(auth);
        throw new Error('Access denied. This portal is for admin accounts only.');
    }

    // Update lastLogin
    await setDoc(doc(db, USERS_COLLECTION, user.uid), {
        lastLogin: serverTimestamp()
    }, { merge: true });

    return { user, userData };
};

/**
 * Signs the current user out.
 */
export const logoutAdmin = async () => {
    await signOut(auth);
};

/**
 * Sends a password reset email.
 */
export const sendAdminPasswordReset = async (email) => {
    await sendPasswordResetEmail(auth, email);
};
