// src/services/reportsService.js
import { db } from './firebaseConfig';
import {
  collection,
  getDocs,
  doc,
  updateDoc,
  getDoc,
  query,
  where,
  orderBy,
  limit,
  startAfter,
  onSnapshot,
  serverTimestamp
} from 'firebase/firestore';

const REPORTS_COLLECTION = 'reports';

/**
 * Fetches reports with filtering, sorting, and pagination.
 * @param {Object} filters - Filter criteria (status, issueType).
 * @param {Object} options - Pagination and sorting options.
 */
export const fetchReports = async (filters = {}, options = {}) => {
  const { status, type } = filters;
  const { sortBy = 'created_at', sortOrder = 'desc', lastVisible, pageSize = 10 } = options;

  try {
    let q = collection(db, REPORTS_COLLECTION);

    const constraints = [];
    if (status) {
      constraints.push(where('status', '==', status));
    }
    if (type) {
      constraints.push(where('type', '==', type));
    }

    constraints.push(orderBy(sortBy, sortOrder));

    if (lastVisible) {
      constraints.push(startAfter(lastVisible));
    }

    constraints.push(limit(pageSize));

    const finalQuery = query(q, ...constraints);
    const querySnapshot = await getDocs(finalQuery);

    const reports = querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      created_at: doc.data().created_at?.toDate?.() || doc.data().created_at,
      updated_at: doc.data().updated_at?.toDate?.() || doc.data().updated_at,
    }));

    return {
      reports,
      lastVisible: querySnapshot.docs[querySnapshot.docs.length - 1]
    };
  } catch (error) {
    console.error("Error fetching reports: ", error);
    throw error;
  }
};

/**
 * Updates a report's status and adds an admin response.
 * @param {string} reportId - The ID of the report.
 * @param {string} status - New status ('open', 'in_progress', 'resolved').
 * @param {string} adminResponse - Admin's response/comment.
 */
export const updateReportStatus = async (reportId, status, adminResponse, priority) => {
  try {
    const reportRef = doc(db, REPORTS_COLLECTION, reportId);
    const updateData = {
      status,
      admin_response: adminResponse,
      updated_at: serverTimestamp()
    };
    if (priority) {
      updateData.priority = priority;
    }
    await updateDoc(reportRef, updateData);
  } catch (error) {
    console.error("Error updating report status: ", error);
    throw error;
  }
};

/**
 * Subscribes to real-time updates for reports.
 * @param {Function} callback - Callback function with updated reports array.
 */
export const subscribeToReports = (filters = {}, callback) => {
  const { status, type } = filters;
  let q = collection(db, REPORTS_COLLECTION);
  const constraints = [];

  if (status) {
    constraints.push(where('status', '==', status));
  }
  if (type) {
    constraints.push(where('type', '==', type));
  }

  constraints.push(orderBy('created_at', 'desc'));
  constraints.push(limit(50));

  const finalQuery = query(q, ...constraints);

  return onSnapshot(finalQuery, (snapshot) => {
    const reports = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      created_at: doc.data().created_at?.toDate?.() || doc.data().created_at,
      updated_at: doc.data().updated_at?.toDate?.() || doc.data().updated_at,
    }));
    callback(reports);
  }, (error) => {
    console.error("Real-time subscription error: ", error);
  });
};
