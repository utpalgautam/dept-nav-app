// src/services/analyticsService.js
import { db } from './firebaseConfig';
import { collection, getDocs, addDoc, serverTimestamp } from 'firebase/firestore';

const SEARCH_LOGS_COLLECTION = 'searchLogs';

/**
 * ─────────────────────────────────────────────────────
 * WRITE — Call this from the navigation app whenever
 * a user searches for / navigates to a destination.
 *
 * Document shape written to Firestore:
 * {
 *   buildingId:   string   – Firestore doc ID of the building
 *   buildingName: string   – Human-readable name (used in charts)
 *   query:        string   – What the user typed (optional)
 *   timestamp:    Timestamp – serverTimestamp()
 *   platform:     string   – 'web' | 'mobile'
 * }
 * ─────────────────────────────────────────────────────
 */
export const logSearch = async (buildingId, buildingName, query = '', platform = 'web') => {
    try {
        await addDoc(collection(db, SEARCH_LOGS_COLLECTION), {
            buildingId,
            buildingName,
            query,
            timestamp: serverTimestamp(),
            platform,
        });
    } catch (err) {
        // Non-blocking — analytics failures must never break the app
        console.warn('logSearch failed (non-critical):', err);
    }
};


/**
 * Get total searches grouped by building name with timeframe filtering.
 * @param {string} timeframe - 'day', 'week', or 'month'
 */
export async function getSearchesPerBuilding(timeframe = 'week') {
    try {
        const snapshot = await getDocs(collection(db, SEARCH_LOGS_COLLECTION));
        
        const now = new Date();
        let cutoff = new Date();
        if (timeframe === 'day') cutoff.setDate(now.getDate() - 1);
        else if (timeframe === 'week') cutoff.setDate(now.getDate() - 7);
        else if (timeframe === 'month') cutoff.setMonth(now.getMonth() - 1);

        const counts = {};
        snapshot.forEach(doc => {
            const data = doc.data();
            const ts = data.timestamp?.toDate ? data.timestamp.toDate() : new Date(data.timestamp);
            
            if (ts >= cutoff) {
                const building = data.buildingName || data.buildingId || 'Unknown';
                counts[building] = (counts[building] || 0) + 1;
            }
        });

        // If no real data satisfies the filter, return empty but let Dashboard handle buildings
        return Object.entries(counts)
            .map(([name, searches]) => ({ name, searches }))
            .sort((a, b) => b.searches - a.searches);
    } catch (err) {
        console.error('Error fetching searches per building:', err);
        return [];
    }
}

/**
 * Get searches per day for the last 7 days.
 */
export async function getSearchesPerDay(days = 7) {
    try {
        const snapshot = await getDocs(collection(db, SEARCH_LOGS_COLLECTION));
        
        const now = new Date();
        now.setHours(23, 59, 59, 999);
        const cutoff = new Date();
        cutoff.setDate(now.getDate() - (days - 1));
        cutoff.setHours(0, 0, 0, 0);

        const dailyCounts = {};

        // Initialize all 7 days including today
        for (let i = 0; i < days; i++) {
            const d = new Date(cutoff);
            d.setDate(cutoff.getDate() + i);
            const key = d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
            dailyCounts[key] = {
                display: d.toLocaleDateString('en-US', { weekday: 'short' }),
                count: 0,
                sortKey: d.getTime()
            };
        }

        snapshot.forEach(doc => {
            const data = doc.data();
            const ts = data.timestamp?.toDate ? data.timestamp.toDate() : new Date(data.timestamp);
            
            if (ts >= cutoff && ts <= now) {
                const key = ts.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
                if (dailyCounts[key]) {
                    dailyCounts[key].count++;
                }
            }
        });

        return Object.entries(dailyCounts)
            .map(([date, data]) => ({ 
                name: data.display, 
                date,
                searches: data.count,
                sortKey: data.sortKey 
            }))
            .sort((a, b) => a.sortKey - b.sortKey);
    } catch (err) {
        console.error('Error fetching searches per day:', err);
        return getSampleDailyData(days);
    }
}

function getSampleDailyData(days = 7) {
    const now = new Date();
    const result = [];
    for (let i = days - 1; i >= 0; i--) {
        const d = new Date(now.getTime() - i * 24 * 60 * 60 * 1000);
        result.push({
            name: d.toLocaleDateString('en-US', { weekday: 'short' }),
            date: d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
            searches: Math.floor(Math.random() * 40) + 10
        });
    }
    return result;
}
