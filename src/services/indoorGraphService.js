// src/services/indoorGraphService.js
import { db } from './firebaseConfig';
import {
    collection,
    doc,
    getDocs,
    query,
    where,
    setDoc,
    updateDoc,
    serverTimestamp,
    getDoc
} from 'firebase/firestore';

const INDOOR_GRAPHS_COLLECTION = 'IndoorGraphs';

/**
 * Get the indoor graph for a specific building and floor
 * @param {string} buildingId 
 * @param {number} floorNo 
 */
export const getIndoorGraph = async (buildingId, floorNo) => {
    try {
        const docId = `${buildingId}_floor_${floorNo}`;
        const docRef = doc(db, INDOOR_GRAPHS_COLLECTION, docId);
        const docSnap = await getDoc(docRef);

        if (docSnap.exists()) {
            return { id: docSnap.id, ...docSnap.data() };
        } else {
            return { buildingId, floorNo, nodes: [], edges: [] };
        }
    } catch (error) {
        console.error("Error fetching indoor graph:", error);
        throw error;
    }
};

/**
 * Save or update the entire indoor graph for a floor
 * @param {string} buildingId 
 * @param {number} floorNo 
 * @param {Object} graphData - { nodes, edges }
 */
export const saveIndoorGraph = async (buildingId, floorNo, graphData) => {
    try {
        const docId = `${buildingId}_floor_${floorNo}`;
        const docRef = doc(db, INDOOR_GRAPHS_COLLECTION, docId);
        
        await setDoc(docRef, {
            buildingId,
            floorNo: Number(floorNo),
            ...graphData,
            updatedAt: serverTimestamp()
        }, { merge: true });

        return { id: docId, ...graphData };
    } catch (error) {
        console.error("Error saving indoor graph:", error);
        throw error;
    }
};

/**
 * Helper to update only nodes or edges
 */
export const updateGraphPartial = async (buildingId, floorNo, part) => {
    try {
        const docId = `${buildingId}_floor_${floorNo}`;
        const docRef = doc(db, INDOOR_GRAPHS_COLLECTION, docId);
        
        await updateDoc(docRef, {
            ...part,
            updatedAt: serverTimestamp()
        });
    } catch (error) {
        // If doc doesn't exist, we might need to create it using setDoc first
        console.error("Error updating graph partial:", error);
        throw error;
    }
};
